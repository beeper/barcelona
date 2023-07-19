//
//  CBPurgedAttachmentController.swift
//  Barcelona
//
//  Processes purged attachments, either downloading them or presenting an error explaining that the attachment is too large
//
//  Created by Eric Rabil on 10/26/21.
//

import Foundation
import IMCore
import IMDPersistence
import IMDaemonCore
import IMFoundation
import IMSharedUtilities
import Logging
import Sentry

public protocol CBPurgedAttachmentControllerDelegate {
    func purgedTransferResolved(_ transfer: IMFileTransfer)
    func purgedTransferFailed(_ transfer: IMFileTransfer)
}

extension CBPurgedAttachmentControllerDelegate {
    public func purgedTransferResolved(_ transfer: IMFileTransfer) {}
    public func purgedTransferFailed(_ transfer: IMFileTransfer) {}
}

extension Notification {
    public func decodeObject<P>(to: P.Type) -> P? {
        let log = Logger(label: "Notifications")
        guard let object = object else {
            return nil
        }
        guard let object = object as? P else {
            log.error(
                "Notified about \(name.rawValue) but the object was \(String(describing: type(of: object))) instead of \(String(describing: P.self))",
                source: "Notifications"
            )
            return nil
        }
        return object
    }
}

enum FileTransferError: CustomNSError, LocalizedError {
    /// Could not find the referenced transfer.
    case transferNotFound(id: String)
    /// Failed to download the attachment.
    case downloadFailed
    /// Downloading the attachment timed out.
    case timeout

    var error: String {
        switch self {
        case .transferNotFound:
            return "transferNotFound"
        case .downloadFailed:
            return "downloadFailed"
        case .timeout:
            return "timeout"
        }
    }

    public var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: error]
    }

    public var errorDescription: String? {
        switch self {
        case .transferNotFound:
            return "Could not find the referenced transfer."
        case .downloadFailed:
            return "Failed to download the attachment."
        case .timeout:
            return "Downloading the attachment timed out."
        }
    }
}

// Automatically downloads purged attachments according to a set of configurable conditions
// Disabled by default!
public class CBPurgedAttachmentController {
    public static let shared = CBPurgedAttachmentController()

    public static var maxBytes: Int = 100_000_000  // default -- 100MB
    public var enabled: Bool = false
    public var delegate: CBPurgedAttachmentControllerDelegate?

    private let log = Logger(label: "PurgedAttachments")

    public func process(transferIDs: [String]) async {
        let transferCenter = IMFileTransferCenter.sharedInstance()
        log.debug("Processing transfers: \(transferIDs)")
        for transferID in transferIDs {
            guard let transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: transferID),
                let guid = transfer.guid
            else {
                log.warning("Could not find a transfer for \(transferID)")
                continue
            }
            log.info("Processing transfer \(guid)")
            log.debug("\(guid) isIncoming: \(transfer.isIncoming), state: \(transfer.state)")
            guard transfer.isIncoming && (transfer.needsUnpurging || !transfer.isTrulyFinished) else {
                log.info("Transfer \(guid) does not need processing, skipping")
                continue
            }
            log.debug("Unpurging \(guid)")

            do {
                _ = try await withThrowingTaskGroup(of: String.self) { group in
                    await withCheckedContinuation { continuation in
                        group.addTask { [log] in
                            if transfer.state != .finished {
                                _ = try await TransferCenter.receivedFinishNotification(
                                    for: guid,
                                    continuation: continuation
                                )
                            }
                            while !transfer.isTrulyFinished {
                                try Task.checkCancellation()
                                log.debug("Waiting for \(guid) to be truly finished")
                                try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
                            }

                            return guid
                        }
                    }

                    log.debug("Registering transfer with daemon")
                    transferCenter.registerTransfer(withDaemon: guid)
                    log.debug("Accepting transfer")
                    transferCenter.acceptTransfer(transfer.guid!)
                    log.debug("Transfer accepted")

                    group.addTask { [log] in
                        await Task.yield()
                        log.debug("Starting a 30s timeout for the transfer")
                        try await Task.sleep(nanoseconds: 30 * NSEC_PER_SEC)
                        log.debug("Reached timeout for the transfer")
                        try Task.checkCancellation()

                        log.debug("Checking if the transfer is finished before timing out")
                        if let transfer = transferCenter.transfer(forGUID: guid), let guid = transfer.guid,
                            transfer.isFinished
                        {
                            log.debug("Transfer is finished with state=\(transfer.state) error=\(transfer.error)")
                            return guid
                        }
                        throw FileTransferError.timeout
                    }

                    defer { group.cancelAll() }
                    log.debug("Waiting for transfer to be finished")
                    let result = try await group.next()!
                    log.debug("Got finished status from observation")
                    return result
                }
                delegate?.purgedTransferResolved(transfer)
            } catch {
                SentrySDK.capture(error: error)
                delegate?.purgedTransferFailed(transfer)
            }
        }
    }
}
