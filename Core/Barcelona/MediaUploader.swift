//
//  MediaUploader.swift
//  Barcelona
//
//  Created by Joonas Myhrberg on 20.4.2023.
//

import Foundation
import IMCore
import IMDaemonCore
import IMSharedUtilities
import Logging

public enum MediaUploadError: CustomNSError, LocalizedError {
    /// Starting the transfer with `IMFileTransferCenter` failed.
    case transferCreationFailed
    /// The underlying `IMFileTransfer` had an error.
    case transferFailed(code: Int64, description: String, isRecoverable: Bool)
    /// Timed out waiting for the transfer to finish.
    case timeout

    var error: String {
        switch self {
        case .transferCreationFailed:
            return "transferCreationFailed"
        case .transferFailed(code: _, let description, let isRecoverable):
            return "transferFailed: \(description), recoverable: \(isRecoverable)"
        case .timeout:
            return "timeout"
        }
    }

    public var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: error]
    }

    public var errorDescription: String? {
        switch self {
        case .transferCreationFailed:
            return "Failed to start the attachment upload"
        case .transferFailed(code: _, let description, isRecoverable: _):
            return "Failed to upload the attachment: \(description)"
        case .timeout:
            return "Timed out waiting for the transfer to finish"
        }
    }
}

public class MediaUploader {

    private let log = Logger(label: "MediaUploader")

    public init() {}

    public func uploadFile(
        filename: String,
        path: URL,
        isAudioMessage: Bool = false
    ) async throws -> String {
        log.debug("Creating file transfer")
        let transfer = try await createFileTransfer(for: filename, path: path, isAudioMessage: isAudioMessage)
        log.debug("Uploading transfer \(transfer.guid ?? "nil")")
        return try await uploadTransfer(transfer)
    }

    public func uploadTransfer(_ transfer: IMFileTransfer) async throws -> String {
        guard let transferGUID = transfer.guid else {
            throw MediaUploadError.transferCreationFailed
        }

        log.debug("Got file transfer with guid: \(transferGUID)")

        let transferCenter = IMFileTransferCenter.sharedInstance()

        return try await withThrowingTaskGroup(of: String.self) { group in
            await withCheckedContinuation { continuation in
                group.addTask {
                    return try await TransferCenter.receivedFinishNotification(
                        for: transferGUID,
                        continuation: continuation
                    )
                }
            }

            log.debug("Registering transfer with daemon")
            transferCenter.registerTransfer(withDaemon: transferGUID)
            log.debug("Accepting transfer")
            transferCenter.acceptTransfer(transfer.guid!)
            log.debug("Transfer accepted")

            group.addTask { [log] in
                await Task.yield()
                log.debug("Starting a 30s timeout for the transfer")
                try await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                log.debug("Reached timeout for the transfer")
                try Task.checkCancellation()

                log.debug("Checking if the transfer is finished before timing out")
                if let transfer = transferCenter.transfer(forGUID: transferGUID), let guid = transfer.guid,
                    transfer.isFinished
                {
                    log.debug("Transfer is finished with state=\(transfer.state) error=\(transfer.error)")
                    return guid
                }
                throw MediaUploadError.timeout
            }

            defer { group.cancelAll() }
            log.debug("Waiting for transfer to be finished")
            let result = try await group.next()!
            log.debug("Got finished status from observation")
            return result
        }
    }

    @MainActor
    public func createFileTransfer(for filename: String, path: URL, isAudioMessage: Bool) async throws -> IMFileTransfer {
        let transferCenter = IMFileTransferCenter.sharedInstance()

        transferCenter.setIssueSandboxEstensionsForTransfers(true)

        log.debug("Getting a guid for a new outgoing transfer")
        let guid = transferCenter.guidForNewOutgoingTransfer(withLocalURL: path, useLegacyGuid: true)
        log.debug("Got guid: \(String(describing: guid)), getting a transfer for it")
        guard let transfer = transferCenter.transfer(forGUID: guid) else {
            throw MediaUploadError.transferCreationFailed
        }
        log.debug("Got transfer")

        log.debug("Getting a persistent path for the transfer")
        if let persistentPath = IMAttachmentPersistentPath(guid, filename, transfer.mimeType, transfer.type) {
            let persistentURL = URL(fileURLWithPath: persistentPath)
            log.debug("Got persistent URL: \(persistentURL)")

            try FileManager.default.createDirectory(
                at: persistentURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            log.debug("Copying file to persistent path")
            try FileManager.default.copyItem(at: path, to: persistentURL)
            log.debug("Retargeting transfer")
            transferCenter.cbRetargetTransfer(transfer, toPath: persistentPath)
            log.debug("Retargeted, setting localURL to: \(persistentURL)")
            transfer.localURL = persistentURL
            log.debug("Retargeted file transfer \(guid ?? "nil") from \(path) to \(persistentURL)")
        } else {
            log.debug("No persistent path for transfer: \(String(describing: guid))")
        }

        if isAudioMessage {
            if transfer.transcoderUserInfo == nil {
                transfer.transcoderUserInfo = ["AVIsOpusAudioMessage": true]
            } else {
                transfer.transcoderUserInfo?["AVIsOpusAudioMessage"] = true
            }

            transfer.attributionInfo = [
                IMFileTransferAttributionInfoPreviewGenerationSucceededKey: true,
                IMFileTransferAttributionInfoPreviewGenerationSizeWidthKey: 0.0,
                IMFileTransferAttributionInfoPreviewGenerationSizeHeightKey: 0.0,
                IMFileTransferAttributionInfoPreviewGenerationConstraintsKey: [
                    "mpw": "0.0",
                    "mtw": "0.0",
                    "mth": "0.0",
                    "s": "0.0",
                    "st": 0,
                    "gm": 0
                ] as [String : Any]
            ]
        }


        /*log.debug("Setting a filename for the transfer")
        transfer.transferredFilename = filename*/

        return transfer
    }
}
