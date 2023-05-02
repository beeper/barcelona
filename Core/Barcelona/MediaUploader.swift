//
//  MediaUploader.swift
//  Barcelona
//
//  Created by Joonas Myhrberg on 20.4.2023.
//

import Foundation
import IMCore
import IMSharedUtilities
import Logging

public enum MediaUploadError: CustomNSError, LocalizedError {
    /// Starting the transfer with `IMFileTransferCenter` failed.
    case transferCreationFailed
    /// Observing the status of an `IMFileTransfer` using notifications failed.
    case tranferObservationFailed
    /// The underlying `IMFileTransfer` had an error.
    case transferFailed(code: Int64, description: String, isRecoverable: Bool)
    /// Timed out waiting for the transfer to finish.
    case timeout

    var error: String {
        switch self {
        case .transferCreationFailed:
            return "transferCreationFailed"
        case .tranferObservationFailed:
            return "tranferObservationFailed"
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
        case .tranferObservationFailed:
            return "Failed to get the status of the attachment upload"
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

    public func uploadFile(filename: String, path: URL) async throws -> String {
        let transferCenter = IMFileTransferCenter.sharedInstance()
        log.debug("Creating file transfer")
        let transfer = try await createFileTransfer(for: filename, path: path)
        guard let transferGUID = transfer.guid else {
            throw MediaUploadError.transferCreationFailed
        }
        log.debug("Got file transfer with guid: \(transferGUID)")

        return try await withThrowingTaskGroup(of: String.self) { group in
            await withCheckedContinuation { continuation in
                group.addTask { [weak self] in
                    guard let self else {
                        throw CancellationError()
                    }
                    return try await receivedFinishNotification(for: transferGUID, continuation: continuation)
                }
            }

            log.debug("Registering transfer with daemon")
            transferCenter.registerTransfer(withDaemon: transferGUID)
            log.debug("Accepting transfer")
            transferCenter.acceptTransfer(transfer.guid!)
            log.debug("Transfer accepted")

            group.addTask { [weak self] in
                guard let self else {
                    throw CancellationError()
                }
                await Task.yield()
                log.debug("Starting a 30s timeout for the transfer")
                try await Task.sleep(nanoseconds: 30 * 1000000000)
                log.debug("Reached timeout for the transfer")
                try Task.checkCancellation()

                log.debug("Checking if the transfer is finished before timing out")
                if let transfer = transferCenter.transfer(forGUID: transferGUID), let guid = transfer.guid, transfer.isFinished {
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

    private func receivedFinishNotification(for transferGUID: String, continuation: CheckedContinuation<Void, Never>) async throws -> String {
        log.debug("Starting observation task")
        let updated = NotificationCenter.default.publisher(for: .IMFileTransferUpdated).print("transferUpdated")
        let finished = NotificationCenter.default.publisher(for: .IMFileTransferFinished).print("transferFinished")
        let transferEvents = updated.merge(with: finished)
            .receive(on: DispatchQueue.global(qos: .userInitiated))

        log.debug("Start notification loop")
        continuation.resume()
        for try await notification in transferEvents.values {
            try Task.checkCancellation()
            log.debug("Handling transfer status event")
            guard let transfer = notification.object as? IMFileTransfer else {
                log.error("Got transfer notification with non-transfer data")
                throw MediaUploadError.tranferObservationFailed
            }

            guard let guid = transfer.guid else {
                log.debug("Got transfer notification with nil guid, skipping")
                continue
            }

            guard guid == transferGUID else {
                log.debug("Got notification for guid: \(guid) but interested in \(transferGUID), skipping")
                continue
            }

            log.info("Got transfer event notification for: \(guid) with state: \(transfer.state)")

            switch transfer.state {
            case .finished:
                log.debug("Transfer \(guid) isFinished: \(transfer.isFinished)")
                return guid
            case .error:
                if transfer.error == 24 {
                    log.info("Got error 24 when uploading attachment, treating as success")
                    log.debug(
                        "Transfer exists at local path: \(transfer.existsAtLocalPath), isFinished: \(transfer.isFinished)"
                    )
                    return guid
                }
                log.error(
                    "Transfer \(guid) has an error: \(transfer.error) with description: \(String(describing: transfer.errorDescription))"
                )
                throw MediaUploadError.transferFailed(
                    code: transfer.error,
                    description: transfer.errorDescription ?? "unknown error",
                    isRecoverable: false
                )
            case .recoverableError:
                log.error(
                    "Transfer \(guid) has an recoverable error: \(transfer.error) with description: \(String(describing: transfer.errorDescription))"
                )
                throw MediaUploadError.transferFailed(
                    code: transfer.error,
                    description: transfer.errorDescription ?? "unknown error",
                    isRecoverable: true
                )
            default:
                log.debug("Transfer state \(transfer.state) is of no interest to us, skipping")
                continue
            }
        }

        throw MediaUploadError.tranferObservationFailed
    }

    @MainActor
    private func createFileTransfer(for filename: String, path: URL) throws -> IMFileTransfer {
        let transferCenter = IMFileTransferCenter.sharedInstance()

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

        log.debug("Setting a filename for the transfer")
        transfer.transferredFilename = filename

        return transfer
    }
}
