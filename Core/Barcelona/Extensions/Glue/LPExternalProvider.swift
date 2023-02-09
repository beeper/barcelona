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
import Logging

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

    @MainActor
    func loadLinkMetadata(at url: URL) {
        guard let dataSource = decodePluginDataSource() else {
            return
        }
        guard let richLinkDataSource = dataSource.richLinkDataSource else {
            return
        }

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
    
    func provideLinkMetadata(_ metadata: RichLinkMetadata) throws -> () -> () {
        try provideLinkMetadata(metadata.createLinkMetadata())
    }
    
    func provideLinkMetadata(_ metadata: @autoclosure () -> LPLinkMetadata) throws -> () -> () {
        let log = Logger(label: "IMMessage")
        let payload = IMPluginPayload()
        payload.messageGUID = guid
        payload.pluginBundleID = IMBalloonPluginIdentifierRichLinks
        guard let dataSource = IMBalloonPluginManager.sharedInstance().dataSource(for: payload) else {
            log.warning("Plugin manager returned no data source for rich link plugin payload", source: "LPLink")
            throw IMBalloonPluginDataSource.LPBalloonPluginError.unsupported
        }
        guard let richLinkDataSource = dataSource.richLinkDataSource else {
            log.warning("Rich link data sources have changed, fixme!", source: "LPLink")
            throw IMBalloonPluginDataSource.LPBalloonPluginError.unsupported
        }
        let metadata = metadata()
        richLinkDataSource.setValue(metadata.originalURL, forKey: "_originalURL")
        richLinkDataSource.setValue(false, forKey: "_shouldFetchWhenSent")
        richLinkDataSource.createEmptyMetadataWithOriginalURL()
        richLinkDataSource.richLink.needsCompleteFetch = false
        richLinkDataSource.richLink.needsSubresourceFetch = false
        log.info("Initialized a RichLinkDataSource for message \(self.guid) for URL \(metadata.originalURL?.absoluteString ?? "nil")", source: "LPLink")
        log.info("RichLinkDataSource for message \(guid) willEnterShelf", source: "LPLink")
        dataSource.payloadWillEnterShelf()
        log.info("RichLinkDataSource for message \(guid) willSendFromShelf", source: "LPLink")
        dataSource.payloadWillSendFromShelf()
        payloadData = dataSource.messagePayloadDataForSending
        log.info("RichLinkDataSource for message \(guid) placeholder payload is \(payloadData?.count ?? 0)", source: "LPLink")
        dataSource.payloadInShelf = false
        return {
            log.info("RichLinkDataSource for message \(self.guid) was sent. Time for more!", source: "LPLink")

            richLinkDataSource.updateRichLink(with: metadata)
            richLinkDataSource.dispatchMetadataUpdate()
            var attachments: NSArray?
            let data = richLinkDataSource.richLink.dataRepresentation(withOutOfLineAttachments: &attachments)
            log.info("RichLinkDataSource for message \(self.guid) sending packaged payload with size \(data.count) and attachment count \(attachments?.count ?? 0)", source: "LPLink")
            IMDaemonController.sharedInstance().sendBalloonPayload(data, attachments: attachments as! [Any]?, withMessageGUID: self.guid, bundleID: IMBalloonPluginIdentifierRichLinks)
        }
    }
}

extension IMBalloonPluginDataSource {
    var fileTransferURLs: [URL] {
        pluginPayload?.attachments ?? []
    }
}
