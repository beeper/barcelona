//
//  CBFileTransfer.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore

/// Registers a file transfer with imagent for the given filename and path.
/// The returned file transfer is ready to be sent by including its GUID in a message.
public func CBInitializeFileTransfer(filename: String, path: URL) -> IMFileTransfer {
    let guid = IMFileTransferCenter.sharedInstance().guidForNewOutgoingTransfer(withLocalURL: path)
    
    let transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: guid)!
    transfer.transferredFilename = filename
    
    IMFileTransferCenter.sharedInstance().registerTransfer(withDaemon: guid)
    
    transfer.shouldForceArchive = true
    IMFileTransferCenter.sharedInstance().sendTransfer(transfer)
    
    return transfer
}
