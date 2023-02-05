//
//  LPExternalProvider.swift
//  Barcelona
//
//  Created by Eric Rabil on 2/15/22.
//

import Foundation
import IMCore
import LinkPresentation
import LinkPresentationPrivate
import IMSharedUtilities
import Swog

internal extension IMBalloonPluginManager {
    var richLinkPlugin: IMBalloonPlugin? {
        balloonPlugin(forBundleID: "com.apple.messages.URLBalloonProvider")
    }
}

@objc private protocol RichLinkPluginDataSource: NSObjectProtocol {
    @objc(_didFetchMetadata:error:)
    func _didFetchMetadata(_ metadata: LPLinkMetadata!, error: NSErrorPointer)
    @objc(updateRichLinkWithFetchedMetadata:)
    func updateRichLink(with fetchedMetadata: LPLinkMetadata)
    func _startFetchingMetadata()
    func dispatchMetadataUpdate()
    @objc var richLink: LPMessagesPayload { get }
    @objc(setValue:forKey:) func setValue(_ value: Any!, forKey: String)
    @objc func createEmptyMetadataWithOriginalURL()
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
        return self
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

extension IMBalloonPluginDataSource: RichLinkPluginDataSource {
    func dispatchMetadataUpdate() {
        if #available(macOS 13.0, *) {
            self.dispatchMetadataUpdateToAllClients()
        } else {
            self.dispatchDidReceiveMetadataToAllClients()
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
            let metadata = LPLinkMetadata()
            metadata.originalURL = url
            richLinkDataSource.richLink.isPlaceholder = true
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
    
    func provideLinkMetadata(_ metadata: RichLinkMetadata) throws -> () -> () {
        try provideLinkMetadata(metadata.createLinkMetadata())
    }
    
    func provideLinkMetadata(_ metadata: @autoclosure () -> LPLinkMetadata) throws -> () -> () {
        let payload = IMPluginPayload()
        payload.messageGUID = guid
        payload.pluginBundleID = IMBalloonPluginIdentifierRichLinks
        guard let dataSource = IMBalloonPluginManager.sharedInstance().dataSource(for: payload) else {
            CLWarn("LPLink", "Plugin manager returned no data source for rich link plugin payload")
            throw IMBalloonPluginDataSource.LPBalloonPluginError.unsupported
        }
        guard let richLinkDataSource = dataSource.richLinkDataSource else {
            CLWarn("LPLink", "Rich link data sources have changed, fixme!")
            throw IMBalloonPluginDataSource.LPBalloonPluginError.unsupported
        }
        let metadata = metadata()
        richLinkDataSource.setValue(metadata.originalURL, forKey: "_originalURL")
        richLinkDataSource.setValue(false, forKey: "_shouldFetchWhenSent")
        richLinkDataSource.createEmptyMetadataWithOriginalURL()
        richLinkDataSource.richLink.needsCompleteFetch = false
        richLinkDataSource.richLink.needsSubresourceFetch = false
        CLInfo("LPLink", "Initialized a RichLinkDataSource for message \(self.guid) for URL \(metadata.originalURL?.absoluteString ?? "nil")")
        CLInfo("LPLink", "RichLinkDataSource for message %@ willEnterShelf", guid)
        dataSource.payloadWillEnterShelf()
        CLInfo("LPLink", "RichLinkDataSource for message %@ willSendFromShelf", guid)
        dataSource.payloadWillSendFromShelf()
        payloadData = dataSource.messagePayloadDataForSending
        CLInfo("LPLink", "RichLinkDataSource for message %@ placeholder payload is %d", guid, payloadData?.count ?? 0)
        dataSource.payloadInShelf = false
        return {
            CLInfo("LPLink", "RichLinkDataSource for message %@ was sent. Time for more!", self.guid)

            richLinkDataSource.updateRichLink(with: metadata)
            richLinkDataSource.dispatchMetadataUpdate()
            var attachments: NSArray?
            let data = richLinkDataSource.richLink.dataRepresentation(withOutOfLineAttachments: &attachments)
            CLInfo("LPLink", "RichLinkDataSource for message %@ sending packaged payload with size %d and attachment count %d", self.guid, data.count, attachments?.count ?? 0)
            IMDaemonController.sharedInstance().sendBalloonPayload(data, attachments: attachments as! [Any]?, withMessageGUID: self.guid, bundleID: IMBalloonPluginIdentifierRichLinks)
        }
    }
}

extension IMBalloonPluginDataSource {
    var fileTransferURLs: [URL] {
        pluginPayload?.attachments ?? []
    }
}
