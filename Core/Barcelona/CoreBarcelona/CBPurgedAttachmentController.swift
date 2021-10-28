//
//  CBPurgedAttachmentController.swift
//  Barcelona
//
//  Processes purged attachments, either downloading them or presenting an error explaining that the attachment is too large
//
//  Created by Eric Rabil on 10/26/21.
//

import Foundation
import IMSharedUtilities
import IMFoundation
import IMDPersistence
import IMDaemonCore
import IMCore
import Swog
import Pwomise

public protocol CBPurgedAttachmentControllerDelegate {
    func purgedTransferResolved(_ transfer: IMFileTransfer)
    func purgedTransferFailed(_ transfer: IMFileTransfer)
}

public extension CBPurgedAttachmentControllerDelegate {
    func purgedTransferResolved(_ transfer: IMFileTransfer) {}
    func purgedTransferFailed(_ transfer: IMFileTransfer) {}
}

// Automatically downloads purged attachments according to a set of configurable conditions
// Disabled by default!
public class CBPurgedAttachmentController {
    public static let shared = CBPurgedAttachmentController()
    
    public var maxBytes: Int = 100000000 // default -- 100MB
    public var enabled: Bool = false
    public var delegate: CBPurgedAttachmentControllerDelegate?
    
    private let log = Logger(category: "PurgedAttachments")
    private var processingTransfers: [String: Promise<Void>] = [:] // used to mux together purged transfers, to prevent a race in which two operations are both fetching a transfer
    
    public func process(transferIDs: [String]) -> Promise<Void> {
        let (transfers, supplemented) = transferIDs
            .compactMap(IMFileTransferCenter.sharedInstance().transfer(forGUID:))
            .filter { transfer in
                transfer.state == .waitingForAccept && !transfer.canAutoDownload && maxBytes > transfer.totalBytes
            }.splitReduce(intoLeft: [IMFileTransfer](), intoRight: [Promise<Void>]()) { transfers, promises, transfer in
                if let pendingPromise = processingTransfers[transfer.guid] {
                    promises.append(pendingPromise) // existing download in progress, return that instead
                } else {
                    transfers.append(transfer) // clear for takeoff
                }
            }
        
        guard transfers.count > 0 else {
            if supplemented.count > 0 {
                return Promise.all(supplemented).replace(with: ()) // return summative promise over all existing operations
            }
            
            return .success(())
        }
        
        log("fetching \(transfers.count, privacy: .public) guids from cloudkit")
        
        return Promise.all(supplemented + transfers.map { transfer in
            let promise = Promise<Void> { resolve, reject in
                NotificationCenter.default.addObserver(forName: .IMFileTransferUpdated, object: nil, queue: .main) { notification, unsubscribe in
                    guard let object = notification.object as? IMFileTransfer, object.guid == transfer.guid else {
                        return
                    }
                    
                    self.log.debug("transfer \(transfer.guid) moved to state \(object.state)")
                    
                    switch object.state {
                    case .finished:
                        unsubscribe()
                        resolve(())
                    case .recoverableError:
                        fallthrough
                    case .error:
                        unsubscribe()
                        reject(BarcelonaError(code: 500, message: "Failed to download file transfer: \(object.errorDescription ?? object.error.description)"))
                    default:
                        return
                    }
                }
            }.observeOutput {
                self.processingTransfers.removeValue(forKey: transfer.guid)
                self.delegate?.purgedTransferResolved(transfer)
            }.observeFailure { _ in
                self.delegate?.purgedTransferFailed(transfer)
            }
            
            processingTransfers[transfer.guid] = promise
            
            IMFileTransferCenter.sharedInstance().acceptTransfer(transfer.guid)
            
            return promise
        }).replace(with: ())
    }
}
