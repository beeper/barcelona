//
//  LPExternalProvider.swift
//  Barcelona
//
//  Created by Eric Rabil on 2/15/22.
//

import Foundation
import IMCore
import IMSharedUtilities
import LinkPresentation
import LinkPresentationPrivate
import Logging
import Combine

extension IMBalloonPluginManager {
    var richLinkPlugin: IMBalloonPlugin? {
        balloonPlugin(forBundleID: "com.apple.messages.URLBalloonProvider")
    }
}

@objc private protocol RichLinkPluginDataSource: NSObjectProtocol {
    @objc(updateRichLinkWithFetchedMetadata:)
    func updateRichLink(with fetchedMetadata: LPLinkMetadata)
    func dispatchMetadataUpdate()
    @objc var richLink: LPMessagesPayload { get }
    @objc(setValue:forKey:) func setValue(_ value: Any!, forKey: String)
    @objc func createEmptyMetadataWithOriginalURL()
}

extension IMBalloonPluginDataSource {
    enum LPBalloonPluginError: Error {
        case unsupported  // fuck
    }

    fileprivate var richLinkDataSource: RichLinkPluginDataSource? {
        guard bundleID == IMBalloonPluginManager.sharedInstance().richLinkPlugin?.identifier else {
            return nil
        }
        return self
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

extension IMMessage {
    public func provideLinkMetadata(_ metadata: RichLinkMetadata) throws -> () -> Void {
        try provideLinkMetadata(metadata.createLinkMetadata())
    }

    public func provideLinkMetadata(_ metadata: @autoclosure () -> LPLinkMetadata) throws -> () -> Void {
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
        log.info(
            "Initialized a RichLinkDataSource for message \(String(describing: guid)) for URL \(metadata.originalURL?.absoluteString ?? "nil")",
            source: "LPLink"
        )
        log.info("RichLinkDataSource for message \(String(describing: guid)) willEnterShelf", source: "LPLink")
        dataSource.payloadWillEnterShelf()
        log.info("RichLinkDataSource for message \(String(describing: guid)) willSendFromShelf", source: "LPLink")
        dataSource.payloadWillSendFromShelf()
        payloadData = dataSource.messagePayloadDataForSending
        log.info(
            "RichLinkDataSource for message \(String(describing: guid)) placeholder payload is \(payloadData?.count ?? 0)",
            source: "LPLink"
        )
        dataSource.payloadInShelf = false
        return {
            log.info("RichLinkDataSource for message \(String(describing: self.guid)) was sent. Time for more!", source: "LPLink")

            richLinkDataSource.updateRichLink(with: metadata)
            richLinkDataSource.dispatchMetadataUpdate()
            var attachments: NSArray?
            let data = richLinkDataSource.richLink.dataRepresentation(withOutOfLineAttachments: &attachments)
            log.info(
                "RichLinkDataSource for message \(String(describing: self.guid)) sending packaged payload with size \(data.count) and attachment count \(attachments?.count ?? 0)",
                source: "LPLink"
            )
            IMDaemonController.sharedInstance()
                .sendBalloonPayload(
                    data,
                    attachments: attachments as! [Any]?,
                    withMessageGUID: self.guid,
                    bundleID: IMBalloonPluginIdentifierRichLinks
                )
        }
    }
}
