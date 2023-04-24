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

// Automatically downloads purged attachments according to a set of configurable conditions
// Disabled by default!
public class CBPurgedAttachmentController {
    public static let shared = CBPurgedAttachmentController()

    public static var maxBytes: Int = 100_000_000  // default -- 100MB
    public var enabled: Bool = false
    public var delegate: CBPurgedAttachmentControllerDelegate?

    private let log = Logger(label: "PurgedAttachments")
    private var processingTransfers: [String: Promise<Void>] = [:]  // used to mux together purged transfers, to prevent a race in which two operations are both fetching a transfer

    public func process(transferIDs: [String]) -> Promise<Void> {
        let (transfers, supplemented) =
            transferIDs
            .compactMap(IMFileTransferCenter.sharedInstance().transfer(forGUID:))
            .filter {
                $0.isIncoming
            }
            .filter { transfer in
                transfer.needsUnpurging || !transfer.isTrulyFinished
            }
            .splitReduce(intoLeft: [IMFileTransfer](), intoRight: [Promise<Void>]()) { transfers, promises, transfer in
                guard let guid = transfer.guid else {
                    // we cant do anything, and we certainly wont wait!
                    promises.append(Promise.success(()))
                    return
                }
                if let pendingPromise = processingTransfers[guid] {
                    promises.append(pendingPromise)  // existing download in progress, return that instead
                } else {
                    transfers.append(transfer)  // clear for takeoff
                }
            }

        guard transfers.count > 0 else {
            if supplemented.count > 0 {
                return Promise.all(supplemented).replace(with: ())  // return summative promise over all existing operations
            }

            return .success(())
        }

        log.info("fetching \(transfers.count) guids from cloudkit")

        return
            Promise.all(
                supplemented
                    + transfers.map { transfer in
                        guard let guid = transfer.guid else {
                            log.error(
                                "Transfers were filtered out to only the ones with GUIDs, but encountered a transfer without one."
                            )
                            return Promise.success(())
                        }

                        var promise = CBFileTransferCenter.shared.transferCompletionPromise(guid)

                        guard transfer.needsUnpurging else {
                            return promise
                        }

                        promise =
                            promise.observeOutput {
                                self.processingTransfers.removeValue(forKey: guid)
                                self.delegate?.purgedTransferResolved(transfer)
                            }
                            .observeFailure { _ in
                                self.delegate?.purgedTransferFailed(transfer)
                            }

                        processingTransfers[guid] = promise

                        IMFileTransferCenter.sharedInstance().acceptTransfer(transfer.guid)

                        return promise
                    }
            )
            .replace(with: ()).resolve(on: DispatchQueue.main).timeout(.seconds(60))
            .then { result in
                switch result {
                case .timedOut:
                    let unavailableTransfers = transfers.filter { !$0.isTrulyFinished }
                    if unavailableTransfers.isEmpty {
                        self.log.error(
                            "File transfer completion promise never fired, but all attachments seem to have finished."
                        )
                    } else {
                        let transferIDS = unavailableTransfers.map(\.guid)
                        self.log.warning(
                            "Continuing message processing despite unsuccessful attachment loading! The following transfers are incomplete/unavailable: \(transferIDS)"
                        )
                    }
                default:
                    break
                }
            }
    }
}

extension Promise {
    func timeout(_ interval: DispatchTimeInterval) -> Promise<TimedResult> {
        Promise<Any>
            .any([
                OpaquePromise(self),
                OpaquePromise(
                    Promise<Void> { resolve in
                        guard let queue = resolveQueue as? DispatchQueue else {
                            preconditionFailure("This timeout implementation only supports libdispatch")
                        }
                        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
                        timer.schedule(deadline: .now().advanced(by: interval))
                        timer.setEventHandler(handler: { resolve(()) })
                        timer.resume()
                    }
                ),
            ])
            .then { output in
                switch output {
                case let output as Output:
                    return .finished(output)
                default:
                    return .timedOut
                }
            }
    }
}
