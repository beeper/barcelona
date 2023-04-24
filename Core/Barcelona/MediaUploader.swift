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

    var error: String {
        switch self {
        case .transferCreationFailed:
            return "transferCreationFailed"
        case .tranferObservationFailed:
            return "tranferObservationFailed"
        case .transferFailed(code: _, let description, let isRecoverable):
            return "transferFailed: \(description), recoverable: \(isRecoverable)"
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
        }
    }
}

public class MediaUploader {

    private let log = Logger(label: "MediaUploader")

    public init() {}

    public func uploadFile(filename: String, path: URL) async throws -> String {
        let transfer = try await createFileTransfer(for: filename, path: path)
        guard let transferGUID = transfer.guid else {
            throw MediaUploadError.transferCreationFailed
        }

        let updated = NotificationCenter.default.publisher(for: .IMFileTransferUpdated)
        let finished = NotificationCenter.default.publisher(for: .IMFileTransferFinished)
        let transferEvents = updated.merge(with: finished)
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)

        for try await notification in transferEvents.values {
            guard let transfer = notification.object as? IMFileTransfer else {
                throw MediaUploadError.tranferObservationFailed
            }

            guard let guid = transfer.guid, guid == transferGUID else {
                continue
            }

            log.info("Got transfer event notification for: \(guid) with state: \(transfer.state)")

            switch transfer.state {
            case .finished:
                log.debug("Transfer \(guid) isFinished: \(transfer.isFinished)")
                return guid
            case .error:
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
                continue
            }
        }

        throw MediaUploadError.tranferObservationFailed
    }

    @MainActor
    private func createFileTransfer(for filename: String, path: URL) throws -> IMFileTransfer {
        let transferCenter = IMFileTransferCenter.sharedInstance()

        let guid = transferCenter.guidForNewOutgoingTransfer(withLocalURL: path, useLegacyGuid: true)
        guard let transfer = transferCenter.transfer(forGUID: guid) else {
            throw MediaUploadError.transferCreationFailed
        }

        if let persistentPath = IMAttachmentPersistentPath(guid, filename, transfer.mimeType, transfer.type) {
            let persistentURL = URL(fileURLWithPath: persistentPath)

            try FileManager.default.createDirectory(
                at: persistentURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try FileManager.default.copyItem(at: path, to: persistentURL)
            transferCenter.cbRetargetTransfer(transfer, toPath: persistentPath)
            transfer.localURL = persistentURL
            log.info(
                "Retargeted file transfer \(guid ?? "nil") from \(path) to \(persistentURL)",
                source: "CBFileTransfer"
            )
        } else {
            log.debug("No persistent path for transfer: \(String(describing: guid))")
        }

        transfer.transferredFilename = filename
        transferCenter.registerTransfer(withDaemon: guid)
        transferCenter.acceptTransfer(transfer.guid!)

        return transfer
    }
}
