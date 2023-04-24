//
//  CBFileTransferCenter.swift
//  Barcelona
//
//  Created by Joonas Myhrberg on 24.4.2023.
//

import Foundation
import IMCore
import Logging

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
                        self.log.debug(
                            "Transfer \(transfer.guid ?? "nil") is still not done: \(transfer.localPath as String?) \(transfer.isFinished) \(transfer.existsAtLocalPath) \(!transfer.inSandboxedLocation)"
                        )
                    }
                }
                timer.schedule(deadline: .now().advanced(by: .milliseconds(200)), repeating: .milliseconds(200))
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
        guard let transfer = notification.decodeObject(to: IMFileTransfer.self), transfer.isIncoming else {
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
        guard let transfer = notification.decodeObject(to: IMFileTransfer.self), transfer.isIncoming else {
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

extension DispatchQueue {
    fileprivate func makeOperationQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.underlyingQueue = self
        return queue
    }
}
