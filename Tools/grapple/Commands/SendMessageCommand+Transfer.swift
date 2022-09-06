//
//  SendMessageCommand+Transfer.swift
//  barcelona
//
//  Created by Eric Rabil on 8/22/22.
//

import Foundation
import SwiftCLI
import IMCore
import IMSharedUtilities
import Barcelona

// TODO: Use Barcelona's export of this once migrated to SPM
/// Registers a file transfer with imagent for the given filename and path.
/// The returned file transfer is ready to be sent by including its GUID in a message.
private func CBInitializeFileTransfer(filename: String, path: URL) -> Barcelona.IMFileTransfer {
    var transfer: IMFileTransfer!
    Thread.main.sync {
        var guid: String
        if #available(macOS 11.0, *) {
            guid = IMFileTransferCenter.sharedInstance().guidForNewOutgoingTransfer(withLocalURL: path, useLegacyGuid: true)
        } else {
            guid = IMFileTransferCenter.sharedInstance().guidForNewOutgoingTransfer(withLocalURL: path)
        }
        transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: guid)!
        if let persistentPath = IMAttachmentPersistentPath(guid, filename, transfer.mimeType, transfer.type) {
            let persistentURL = URL(fileURLWithPath: persistentPath)
            do {
                try FileManager.default.createDirectory(at: persistentURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.copyItem(at: path, to: persistentURL)
                IMFileTransferCenter.sharedInstance().retargetTransfer(transfer, toPath: persistentPath)
                transfer.localURL = persistentURL
                CLInfo("CBFileTransfer", "Retargeted file transfer \(guid) from \(path) to \(persistentURL)")
            } catch {
                CLFault("CBFileTransfer", "Failed to retarget file transfer \(guid) from \(path) to \(persistentURL): \(String(describing: error))")
            }
        }
        
        transfer.transferredFilename = filename
        
        IMFileTransferCenter.sharedInstance().registerTransfer(withDaemon: guid)
    }
    return transfer
}

extension MessageCommand.Send {
    class Transfer: BarcelonaCommand, ChatCommandLike, ChatSMSForcingCapable {
        let name = "transfer"
        
        @Param var destination: String
        
        @Flag("-i", "--id", description: "treat the destination as a chat ID")
        var isID: Bool
        
        @Flag("-s") var sms: Bool
        
        @CollectedParam var transfers: [String]
        var monitor: BLMediaMessageMonitor?
        
        func execute() throws {
            let fileTransfers: [IMFileTransfer] = transfers.map {
                let url = URL(fileURLWithPath: $0)
                return CBInitializeFileTransfer(filename: url.lastPathComponent, path: url)
            }
            let creation = CreateMessage(parts: fileTransfers.compactMap(\.guid).map {
                .init(type: .attachment, details: $0)
            })
            var messageID: String = ""
            monitor = BLMediaMessageMonitor(messageID: messageID, transferGUIDs: fileTransfers.compactMap(\.guid)) { success, error, cancel in
                print(success, error, cancel)
                exit(0)
            }
            let message = try chat.sendReturningRaw(message: creation)
            messageID = message.id
        }
    }
}
