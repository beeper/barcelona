//
//  ChatCommands.swift
//  grapple
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import SwiftCLI
import SwiftyTextTable

class ChatCommands: CommandGroup {
    let name = "chat"
    let shortDescription = "commands for interacting with chats"
    
    class ListChats: Command {
        let name = "list"
        
        func execute() throws {
            print("printing most recent 20 chats")
            
            var table = TextTable(columns: [.init(header: "ID"), .init(header: "Name")])
            
            for chat in Chat.allChats.prefix(20) {
                table.addRow(values: [chat.id, chat.displayName ?? chat.participantNames.joined(separator: ", ")])
            }
            
            print(table.render())
            exit(0)
        }
    }
    
    class RecentMessages: Command {
        let name = "recent-messages"
        
        @Param var id: String
        
        func execute() throws {
            CBLoadChatItems(withChatIdentifier: "chat32445357915332717", onServices: [.iMessage, .SMS], limit: 20).then {
                print($0)
                exit(0)
            }
        }
    }
    
    var children: [Routable] = [ListChats(), RecentMessages()]
}
