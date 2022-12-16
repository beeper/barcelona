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
