//
//  CBFileTransfer.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore
import IMSharedUtilities
import Logging

/// Registers a file transfer with imagent for the given filename and path.
/// The returned file transfer is ready to be sent by including its GUID in a message.
public func CBInitializeFileTransfer(filename: String, path: URL) -> IMFileTransfer {
    let log = Logger(label: "CBInitializeFileTransfer")
    var transfer: IMFileTransfer!
    Thread.main.sync {
        var guid: String
        if #available(macOS 11.0, *) {
            guid = IMFileTransferCenter.sharedInstance()
                .guidForNewOutgoingTransfer(withLocalURL: path, useLegacyGuid: true)
        } else {
            guid = IMFileTransferCenter.sharedInstance().guidForNewOutgoingTransfer(withLocalURL: path)
        }
        transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: guid)!
        if let persistentPath = IMAttachmentPersistentPath(guid, filename, transfer.mimeType, transfer.type) {
            let persistentURL = URL(fileURLWithPath: persistentPath)
            do {
                try FileManager.default.createDirectory(
                    at: persistentURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                try FileManager.default.copyItem(at: path, to: persistentURL)
                IMFileTransferCenter.sharedInstance().cbRetargetTransfer(transfer, toPath: persistentPath)
                transfer.localURL = persistentURL
                log.info("Retargeted file transfer \(guid) from \(path) to \(persistentURL)", source: "CBFileTransfer")
            } catch {
                log.error(
                    "Failed to retarget file transfer \(guid) from \(path) to \(persistentURL): \(String(describing: error))",
                    source: "CBFileTransfer"
                )
            }
        }

        transfer.transferredFilename = filename

        IMFileTransferCenter.sharedInstance().registerTransfer(withDaemon: guid)
    }
    return transfer
}

extension IMFileTransferCenter {
    public func cbRetargetTransfer(_ transfer: IMFileTransfer, toPath path: String) {
        if #available(macOS 13.0, iOS 16.0, *) {
            retargetTransfer(transfer.guid, toPath: path)
        } else {
            retargetTransfer(transfer, toPath: path)
        }
    }
}
