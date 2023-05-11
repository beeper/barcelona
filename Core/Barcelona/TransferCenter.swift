//
//  TransferCenter.swift
//  Barcelona
//
//  Created by Joonas Myhrberg on 5.5.2023.
//

import Extensions
import Foundation
import IMCore
import Logging

public enum TransferError: CustomNSError, LocalizedError {
    /// Observing the status of an `IMFileTransfer` using notifications failed.
    case observationFailed

    var error: String {
        switch self {
        case .observationFailed:
            return "tranferObservationFailed"
        }
    }

    public var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: error]
    }

    public var errorDescription: String? {
        switch self {
        case .observationFailed:
            return "Failed to get the status of the attachment upload"
        }
    }
}

class TransferCenter {

    private static let log = Logger(label: "TransferCenter")

    static func receivedFinishNotification(
        for transferGUID: String,
        continuation: CheckedContinuation<Void, Never>
    ) async throws -> String {
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
                throw TransferError.observationFailed
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

        throw TransferError.observationFailed
    }
}
