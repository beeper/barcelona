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
        var transfers = transferIDs.compactMap(IMFileTransferCenter.sharedInstance().transfer(forGUID:)).filter { transfer in
            transfer.state == .waitingForAccept
        }
        
        guard transfers.count > 0 else {
            return .success(())
        }
        
        var supplemented: [Promise<Void>] = []
        
        for transfer in transfers {
            if let pendingPromise = processingTransfers[transfer.guid] {
                supplemented.append(pendingPromise) // add pending promise, to be lumped together with the new operations
                transfers.removeAll(where: { $0 == transfer }) // remove already-in-progress transfer so we dont process it
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
                var observer: NSObjectProtocol?
                
                func unsubscribe() {
                    if observer != nil {
                        NotificationCenter.default.removeObserver(observer!)
                        observer = nil
                    }
                }
                
                observer = NotificationCenter.default.addObserver(forName: .IMFileTransferUpdated, object: nil, queue: .main) { notification in
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
