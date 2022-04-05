//
//  LPExternalProvider.swift
//  Barcelona
//
//  Created by Eric Rabil on 2/15/22.
//

import Foundation
import IMCore
import LinkPresentation
import IMSharedUtilities
import Swog

internal extension IMBalloonPluginManager {
    var richLinkPlugin: IMBalloonPlugin? {
        balloonPlugin(forBundleID: "com.apple.messages.URLBalloonProvider")
    }
}

@objc private protocol RichLink: NSObjectProtocol {
    @objc var metadata: LPLinkMetadata { get set }
    @objc var placeholder: Bool {
        @objc(isPlaceholder) get
        @objc(setPlaceholder:) set
    }
    @objc var needsCompleteFetch: Bool { get set }
    @objc var needsSubresourceFetch: Bool { get set }
    @objc(dataRepresentationWithOutOfLineAttachments:)
    func dataRepresentation(withOutOfLineAttachments: AutoreleasingUnsafeMutablePointer<NSArray?>) -> Data
}

@objc private protocol RichLinkPluginDataSource: NSObjectProtocol {
    func _didFetchMetadata(_ metadata: LPLinkMetadata!, error: UnsafeMutablePointer<NSError?>?)
    @objc(updateRichLinkWithFetchedMetadata:)
    func updateRichLink(with fetchedMetadata: LPLinkMetadata)
    func _startFetchingMetadata()
    @objc func dispatchDidReceiveMetadataToAllClients()
    @objc var richLink: RichLink { get }
}

internal extension IMBalloonPluginDataSource {
    enum LPBalloonPluginError: Error {
        case dataSourceMismatch // you provided metadata to a non-rich-link datasource
        case unsupported // fuck
    }
    
    fileprivate var richLinkDataSource: RichLinkPluginDataSource? {
        guard bundleID == IMBalloonPluginManager.sharedInstance().richLinkPlugin?.identifier else {
            return nil
        }
        return unsafeBitCast(self, to: RichLinkPluginDataSource.self)
    }
    
    func provideArbitraryLinkMetadata(_ metadata: LPLinkMetadata) throws {
        guard bundleID == IMBalloonPluginManager.sharedInstance().richLinkPlugin?.identifier else {
            throw LPBalloonPluginError.dataSourceMismatch
        }
        let richLinkDataSource = unsafeBitCast(self, to: RichLinkPluginDataSource.self)
        guard richLinkDataSource.responds(to: #selector(RichLinkPluginDataSource._didFetchMetadata(_:error:))) else {
            throw LPBalloonPluginError.unsupported
        }
        var error: NSError?
        richLinkDataSource._didFetchMetadata(metadata, error: &error)
        if let error = error {
            throw error
        }
    }
}

protocol IMBalloonPluginCarrier {
    var balloonBundleID: String! { get }
    func decodePluginPayload() -> IMPluginPayload?
}

extension IMMessageItem: IMBalloonPluginCarrier {
    func decodePluginPayload() -> IMPluginPayload? {
        guard balloonBundleID != nil else {
            return nil
        }
        return IMPluginPayload(messageItem: self)
    }
}

extension IMMessage: IMBalloonPluginCarrier {
    func decodePluginPayload() -> IMPluginPayload? {
        guard balloonBundleID != nil else {
            return nil
        }
        return IMPluginPayload(message: self)
    }
}

enum IMBalloonPluginMisuseError: Error {
    case iAmNotAPlugin
}

internal extension IMBalloonPluginCarrier {
    func decodePluginDataSource() -> IMBalloonPluginDataSource? {
        guard let plugin = locateBalloonPlugin() else {
            return nil
        }
        guard let payload = decodePluginPayload() else {
            return nil
        }
        return plugin.dataSource(for: payload)
    }
    
    func decodeRichLink() -> LPLinkMetadata? {
        guard let richLinkProvider = IMBalloonPluginManager.sharedInstance().richLinkPlugin else {
            return nil
        }
        guard let plugin = locateBalloonPlugin() else {
            return nil
        }
        guard plugin.identifier == richLinkProvider.identifier else {
            return nil
        }
        guard let dataSource = decodePluginDataSource() else {
            return nil
        }
        return dataSource.richLinkMetadata
    }
    
    func locateBalloonPlugin() -> IMBalloonPlugin? {
        guard let balloonBundleID = balloonBundleID else {
            return nil
        }
        return IMBalloonPluginManager.sharedInstance().balloonPlugin(forBundleID: balloonBundleID)
    }
}

public extension IMMessage {
    private static var retains: [IMMessage: Set<AnyHashable>] = [:]
    
    private func onceSent() -> Promise<Void> {
        if isSent {
            return .success(())
        }
        return Promise { resolve in
            var pipeline: CBPipeline<Void> = .init()
            pipeline = CBDaemonListener.shared.messagePipeline.pipe { message in
                if message.id == self.id, message.isSent {
                    pipeline.cancel()
                    resolve(())
                }
            }
        }
    }
    
    func loadLinkMetadata(at url: URL) {
        guard let dataSource = decodePluginDataSource() else {
            return
        }
        guard let richLinkDataSource = dataSource.richLinkDataSource else {
            return
        }
        
        func _load() {
            let metadata = LPLinkMetadata()!
            metadata.originalURL = url
            richLinkDataSource.richLink.placeholder = true
            richLinkDataSource.richLink.metadata = metadata
            richLinkDataSource.richLink.needsCompleteFetch = true
            richLinkDataSource.richLink.needsSubresourceFetch = true
            dataSource.setValue(url, forKey: "originalURL")
            dataSource.payloadWillSendFromShelf()
            richLinkDataSource._startFetchingMetadata()
            IMMessage.retains[self] = .init(arrayLiteral: metadata, dataSource)
            onceSent().then {
                IMMessage.retains.removeValue(forKey: self)
            }
        }

        if Thread.isMainThread {
            _load()
        } else {
            DispatchQueue.main.sync(execute: _load)
        }
        
//        let sentPromise = onceSent()
//        DispatchQueue.main.async {
//            guard let provider = LPMetadataProvider() else {
//                return
//            }
//            IMMessage.fetchers[self] = provider
//            provider.startFetchingMetadata(for: url) { metadata, error in
//                IMMessage.fetchers.removeValue(forKey: self)
//                guard let metadata = metadata else {
//                    return
//                }
//                sentPromise.then {
//                    richLinkDataSource.updateRichLink(with: metadata)
//                    richLinkDataSource.dispatchDidReceiveMetadataToAllClients()
//                    var attachments: NSArray?
//                    self.payloadData = richLinkDataSource.richLink.dataRepresentation(withOutOfLineAttachments: &attachments)
//                    dataSource.sendPayload(self.payloadData, attachments: attachments)
//                    if let attachments = attachments {
//                        let transferGUIDs = IMFileTransferCenter.sharedInstance().guids(forStoredAttachmentPayloadData: attachments, messageGUID: self.guid) as? [String] ?? []
//                        self.fileTransferGUIDs = transferGUIDs
//                        self._imMessageItem.fileTransferGUIDs = transferGUIDs
//                    }
//                }
//            }
//        }
    }
    
    func provideLinkMetadata(_ metadata: RichLinkMetadata) throws {
        try provideLinkMetadata(metadata.createLinkMetadata())
    }
    
    func provideLinkMetadata(_ metadata: @autoclosure () -> LPLinkMetadata) throws {
        guard let dataSource = decodePluginDataSource() else {
            throw IMBalloonPluginMisuseError.iAmNotAPlugin
        }
        if isSent {
            try dataSource.provideArbitraryLinkMetadata(metadata())
        } else {
            guard let richLinkDataSource = dataSource.richLinkDataSource else {
                throw IMBalloonPluginDataSource.LPBalloonPluginError.dataSourceMismatch
            }
            CLInfo("LPLink", "Period")
//            let metadata = metadata()
//            richLinkDataSource.updateRichLink(with: metadata)
//            richLinkDataSource.dispatchDidReceiveMetadataToAllClients()
            var attachments: NSArray?
//            print(attachments)
            payloadData = richLinkDataSource.richLink.dataRepresentation(withOutOfLineAttachments: &attachments)
//            print(attachments)
            
            let metadata = metadata()
            var pipeline: CBPipeline<Void> = CBPipeline()
            pipeline = CBDaemonListener.shared.messagePipeline.pipe { message in
                if message.id == self.id, message.isSent {
                    pipeline.cancel()
                    richLinkDataSource.updateRichLink(with: metadata)
                    richLinkDataSource.dispatchDidReceiveMetadataToAllClients()
                    self.payloadData = richLinkDataSource.richLink.dataRepresentation(withOutOfLineAttachments: &attachments)
                    dataSource.sendPayload(self.payloadData, attachments: attachments)
                }
            }
            
            if let attachments = attachments {
                let transferGUIDs = IMFileTransferCenter.sharedInstance().guids(forStoredAttachmentPayloadData: attachments, messageGUID: guid) as? [String] ?? []
                fileTransferGUIDs = transferGUIDs
                _imMessageItem.fileTransferGUIDs = transferGUIDs
//                for transferGUID in transferGUIDs {
//                    IMDaemonController.sharedInstance().sendStandaloneFileTransfer(transferGUID)
//                }
//                print(fileTransferGUIDs)
            }
//            _imMessageItem.fileTransferGUIDs = fileTransferGUIDs
//            setValue((fileTransferGUIDs as NSArray).copy(), forKey: "fileTransferGUIDs")
        }
    }
}

extension IMBalloonPluginDataSource {
    var fileTransferURLs: [URL] {
        pluginPayload?.attachments ?? []
    }
}
