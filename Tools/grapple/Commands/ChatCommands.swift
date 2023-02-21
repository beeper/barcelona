//
//  ChatCommands.swift
//  grapple
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation
import IMCore
import SwiftCLI
import SwiftyTextTable

class ChatCommands: CommandGroup {
    let name = "chat"
    let shortDescription = "commands for interacting with chats"

    class ListChats: EphemeralBarcelonaCommand {
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

    class RecentMessages: BarcelonaCommand {
        let name = "recent-messages"

        @Param var id: String

        func execute() throws {
            BLLoadChatItems(withChats: [.iMessage, .SMS].map { (id, $0) }, limit: 20)
                .then {
                    print($0)
                    exit(0)
                }
        }
    }

    class Participants: CommandGroup {
        let name = "participants"
        let shortDescription = "commands for managing participants"

        class Add: EphemeralBarcelonaCommand {
            let name = "add"

            @Param var chatID: String
            @CollectedParam var participants: [String]

            func execute() throws {
                guard let chat = IMChat.chat(withIdentifier: chatID, onService: .iMessage, style: nil).map(Chat.init)
                else {
                    return print("unknown chatID")
                }

                print(chat.addParticipants(participants))
            }
        }

        class Remove: EphemeralBarcelonaCommand {
            let name = "remove"

            @Param var chatID: String
            @CollectedParam var participants: [String]

            func execute() throws {
                guard let chat = IMChat.chat(withIdentifier: chatID, onService: .iMessage, style: nil).map(Chat.init)
                else {
                    return print("unknown chatID")
                }

                print(chat.removeParticipants(participants))
            }
        }

        var children: [Routable] = [Add(), Remove()]
    }

    var children: [Routable] = [ListChats(), RecentMessages(), Participants()]
}
