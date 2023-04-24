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
import Pwomise

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

enum FileTransferError: Error {
    case transferNotFound(id: String)
    case downloadFailed
}

// Automatically downloads purged attachments according to a set of configurable conditions
// Disabled by default!
public class CBPurgedAttachmentController {
    public static let shared = CBPurgedAttachmentController()

    public static var maxBytes: Int = 100_000_000  // default -- 100MB
    public var enabled: Bool = false
    public var delegate: CBPurgedAttachmentControllerDelegate?

    private let log = Logger(label: "PurgedAttachments")
    private var processingTransfers: [String: Task<Void, Error>] = [:]

    public func process(transferIDs: [String]) async {
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
                if let task = processingTransfers[guid] {
                    log.debug("Transfer \(guid) already processing, returning existing task")
                    try await task.value
                } else {
                    log.debug("Starting unpurging of transfer \(guid)")
                    let task = Task<Void, Error> {
                        log.debug("Accepting transfer \(guid)")
                        IMFileTransferCenter.sharedInstance().acceptTransfer(transfer.guid)

                        log.debug("Waiting for completion of \(guid)")
                        try await waitForCompletion(transferGUID: transferID)
                        log.debug("Transfer \(guid) completed")

                        processingTransfers.removeValue(forKey: guid)
                        self.delegate?.purgedTransferResolved(transfer)
                    }
                    processingTransfers[guid] = task
                    log.debug("Waiting for unpurging of \(guid)")
                    try await task.value
                }
            } catch {
                log.error("Failed to download \(transferID), skipping")
                delegate?.purgedTransferFailed(transfer)
            }
        }
    }

    private func waitForCompletion(transferGUID: String) async throws {
        let updateFinishedNotification = NotificationCenter.default.publisher(for: .IMFileTransferUpdated)
            .filter { [weak self] notification in
                guard let transfer = notification.object as? IMFileTransfer else {
                    return false
                }
                if transfer.guid == transferGUID && transfer.state == .finished {
                    self?.log.debug("Got updated notification for: \(transferGUID) with state: \(transfer.state)")
                    return true
                }
                return false
            }

        let finishedNotification = NotificationCenter.default.publisher(for: .IMFileTransferFinished)
            .filter { [weak self] notification in
                guard let transfer = notification.object as? IMFileTransfer else {
                    return false
                }
                if transfer.guid == transferGUID {
                    self?.log.debug("Got finished notification for: \(transferGUID) with state: \(transfer.state)")
                    return true
                }
                return false
            }

        let updates = updateFinishedNotification.merge(with: finishedNotification)
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)

        for try await notification in updates.values {
            guard let transfer = notification.object as? IMFileTransfer else {
                continue
            }
            guard let transferGUID = transfer.guid else {
                log.warning("Witnessed transferFinished for a transfer with no GUID")
                continue
            }

            switch transfer.actualState {
            case .finished:
                while !transfer.isTrulyFinished {
                    log.debug("Waiting for \(transferGUID) to be truly finished")
                    try await Task.sleep(nanoseconds: 200 * 1_000_000)
                }
                log.debug("Transfer \(transferGUID) is truly finished")

                return
            default:
                throw FileTransferError.downloadFailed
            }
        }
    }
}
