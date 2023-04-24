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
    private var processingTransfers: [String: Promise<Void>] = [:]  // used to mux together purged transfers, to prevent a race in which two operations are both fetching a transfer
    private var processingTransferTasks: [String: Task<Void, Error>] = [:]

    public func process(transferIDs: [String]) async {
        for transferID in transferIDs {
            guard let transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: transferID),
                let guid = transfer.guid
            else {
                continue
            }
            guard transfer.isIncoming && (transfer.needsUnpurging || !transfer.isTrulyFinished) else {
                continue
            }
            do {
                if let task = processingTransferTasks[guid] {
                    try await task.value
                } else {
                    let task = Task<Void, Error> {
                        try await waitForCompletion(transferGUID: transferID)

                        guard transfer.needsUnpurging else {
                            return
                        }

                        IMFileTransferCenter.sharedInstance().acceptTransfer(transfer.guid)

                        processingTransfers.removeValue(forKey: guid)
                        self.delegate?.purgedTransferResolved(transfer)
                    }
                    processingTransferTasks[guid] = task
                    try await task.value
                }
            } catch {
                log.error("Failed to download \(transferID), skipping")
                self.delegate?.purgedTransferFailed(transfer)
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
