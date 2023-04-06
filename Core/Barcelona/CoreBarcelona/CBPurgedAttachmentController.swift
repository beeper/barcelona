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

extension DispatchQueue {
    fileprivate func makeOperationQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.underlyingQueue = self
        return queue
    }
}

extension IMFileTransfer {
    fileprivate var actualState: IMFileTransferState {
        let state = state
        if state == .error, error == 24, existsAtLocalPath {
            // i have no clue what is going on but the attachment is present and usable
            log.debug("have error 24, treating as finished")
            return .finished
        }
        return state
    }
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

class CBFileTransferCenter {
    static let shared = CBFileTransferCenter()

    private let queue = DispatchQueue(label: "com.ericrabil.barcelona.CBFileTransferCenter")
    private lazy var operationQueue = queue.makeOperationQueue()

    init() {
        NotificationCenter.default.addObserver(
            forName: .IMFileTransferCreated,
            object: nil,
            queue: operationQueue,
            using: transferCreated(_:)
        )
        NotificationCenter.default.addObserver(
            forName: .IMFileTransferUpdated,
            object: nil,
            queue: operationQueue,
            using: transferUpdated(_:)
        )
        NotificationCenter.default.addObserver(
            forName: .IMFileTransferFinished,
            object: nil,
            queue: operationQueue,
            using: transferFinished(_:)
        )
    }

    private(set) var transfers: [String: IMFileTransfer] = [:]

    private let log = Logger(label: "FileTransfers")

    private func transferForID(_ id: String) -> IMFileTransfer? {
        if let transfer = transfers[id] {
            return transfer
        }
        if let transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: id) {
            transfers[id] = transfer
            return transfer
        }
        return nil
    }

    private var transferFinishedHandler: [String: [((()) -> Void, (Error) -> Void)]] = [:]

    private func transferTrulyFinishedPromise(_ transfer: IMFileTransfer) -> Promise<Void> {
        Promise { resolve in
            if !transfer.isTrulyFinished {
                let timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
                timer.setEventHandler { [unowned self] in
                    if transfer.isTrulyFinished {
                        log.info(
                            "Transfer \(transfer.guid ?? "nil") is truly finished!",
                            source: "CBFileTransferCenter"
                        )
                        resolve(())
                        timer.cancel()
                    } else {
                        self.log.debug("Transfer \(transfer.guid ?? "nil") is still not done")
                    }
                }
                timer.schedule(deadline: .now().advanced(by: .milliseconds(10)), repeating: .milliseconds(10))
                timer.resume()
            } else {
                resolve(())
            }
        }
        .resolve(on: queue)
    }

    func transferCompletionPromise(_ id: String) -> Promise<Void> {
        queue.sync {
            guard let transfer = transferForID(id) else {
                return .failure(BarcelonaError(code: 404, message: "Unknown transfer with ID \(id)"))
            }
            return Promise { resolve, reject in
                if transfer.isFinished {
                    transferTrulyFinishedPromise(transfer).then(resolve)
                } else {
                    transferFinishedHandler[id, default: []].append((resolve, reject))
                }
            }
            .resolve(on: DispatchQueue.main)
        }
    }

    private func transferCreated(_ notification: Notification) {
        guard let transfer = notification.decodeObject(to: IMFileTransfer.self) else {
            return
        }
        guard let guid = transfer.guid else {
            log.warning("Notified that a transfer was created but the transfer has no GUID.")
            return
        }
        transfers[guid] = transfer
        log.debug("Transfer \(guid) was created!")
    }

    private func transferUpdated(_ notification: Notification) {
        guard let transfer = notification.decodeObject(to: IMFileTransfer.self) else {
            return
        }
        guard let guid = transfer.guid else {
            log.warning("Notified that a transfer was updated but the transfer has no GUID.")
            return
        }
        transfers[guid] = transfer
        log.debug(
            "Transfer \(guid) has updated! isFinished \(transfer.isFinished) state \(transfer.actualState.description) error \(transfer.errorDescription ?? "nil")"
        )
        if transfer.isFinished {
            transferFinished(transfer)
        }
    }

    private func transferFinished(_ transfer: IMFileTransfer) {
        guard let transferGUID = transfer.guid else {
            log.warning("Witnessed transferFinished for a transfer with no GUID")
            return
        }
        transfers[transferGUID] = transfer
        log.debug("Transfer \(transferGUID) has finished!")
        switch transfer.actualState {
        case .finished:
            transferTrulyFinishedPromise(transfer)
                .then {
                    for (resolve, _) in self.transferFinishedHandler[transferGUID, default: []] {
                        resolve(())
                    }
                    self.transferFinishedHandler.removeValue(forKey: transferGUID)
                }
        default:
            for (_, reject) in transferFinishedHandler[transferGUID, default: []] {
                reject(
                    BarcelonaError(
                        code: 500,
                        message:
                            "Failed to download file transfer: \(transfer.errorDescription ?? transfer.error.description)"
                    )
                )
            }
            transferFinishedHandler.removeValue(forKey: transferGUID)
        }
    }

    private func transferFinished(_ notification: Notification) {
        guard let transfer = notification.decodeObject(to: IMFileTransfer.self) else {
            return
        }
        #if DEBUG
        if let transferGUID = transfer.guid {
            log.debug("Notified that transfer \(transferGUID) is finished.")
        }
        #endif
        transferFinished(transfer)
    }
}

extension IMFileTransfer {

    public var log: Logging.Logger {
        Logger(label: "IMFileTransfer")
    }

    public var inSandboxedLocation: Bool {
        log.debug("checking inSandboxedLocation for localPath: \(localPath as String?)")
        return localPath.hasPrefix("/var/folders")
    }

    public var isTrulyFinished: Bool {
        isFinished && existsAtLocalPath && !inSandboxedLocation
    }

    public var needsUnpurging: Bool {
        state == .waitingForAccept && canAutoDownload && CBPurgedAttachmentController.maxBytes > totalBytes
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
