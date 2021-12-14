//
//  File.swift
//  grapple
//
//  Created by Eric Rabil on 12/14/21.
//

import Foundation
import SwiftCLI
import Barcelona
import IMCore

struct ChatDiagnostics: Codable {
    static func diagnostics(forChat id: String, recentMessagesCount: Int) -> Promise<ChatDiagnostics?> {
        guard let chat = Chat.resolve(withIdentifier: id) else {
            return .success(nil)
        }
        
        return chat.messages(before: nil, limit: 50, beforeDate: nil).then { messages in
            let handles = chat.participants.map(Handle.init(id:))
            
            return ChatDiagnostics(chat: chat,
                                   myHandle: chat.imChat.lastAddressedHandleID,
                                   participants: chat.participants.map(Handle.init(id:)),
                                   contacts: handles.compactDictionary(keyedBy: \.id, valuedBy: \.contact),
                                   recentMessages: messages)
        }
    }
    
    var chat: Chat
    var myHandle: String
    var participants: [Handle]
    var contacts: [String: Contact]
    var recentMessages: [Message]
}

struct AccountDiagnostics: Codable {
    init(account: IMAccount) {
        activeAliases = account.aliases
        allAliases = account.vettedAliases.compactMap { $0 as? String }
        serviceID = account.serviceName
        registered = account.isRegistered
        active = account.isActive
        connected = account.isConnected
        connecting = account.isConnecting
        id = account.uniqueID
        registrationStatus = account.registrationStatus.rawValue
        registrationFailureReason = account.registrationFailureReason.rawValue
    }
    
    var activeAliases: [String]
    var allAliases: [String]
    var serviceID: String
    var registered: Bool
    var active: Bool
    var connected: Bool
    var connecting: Bool
    var id: String?
    var registrationStatus: Int
    var registrationFailureReason: Int
}

extension Encodable {
    var prettyJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        return try! String(decoding: encoder.encode(encode(to:)), as: UTF8.self)
    }
}

class DiagsCommand: CommandGroup {
    let name = "diags"
    let shortDescription = "do diagnostics on different imessage components"
    
    class AccountsCommand: BarcelonaCommand {
        let name = "accounts"
        
        func execute() throws {
            print(IMAccountController.shared.accounts.map(AccountDiagnostics.init(account:)).prettyJSON)
            exit(0)
        }
    }
    
    class MessagesCommand: BarcelonaCommand {
        let name = "messages"
        
        @Param var chatID: String?
        
        func execute() throws {
            CBDaemonListener.shared.messagePipeline.pipe { message in
                if let chatID = self.chatID {
                    guard message.chatID == chatID else {
                        return
                    }
                }
                
                print(message.prettyJSON)
            }
        }
    }
    
    class ChatListCommand: BarcelonaCommand {
        let name = "chatlist"
        
        @Key("--login") var loginHandleFilter: String?
        
        func execute() throws {
            var chats = Chat.allChats
            
            if let loginHandleFilter = loginHandleFilter {
                chats = chats.filter {
                    $0.imChat.lastAddressedHandleID == loginHandleFilter
                }
            }
            
            print(chats.dictionary(keyedBy: \.id, valuedBy: \.participants).prettyJSON)
            exit(0)
        }
    }
    
    class ChatDiagsCommand: BarcelonaCommand {
        let name = "chat"
        
        @Param var id: String
        
        @Key("-l") var limit: Int?
        
        func execute() throws {
            ChatDiagnostics.diagnostics(forChat: id, recentMessagesCount: limit ?? 25).then { diagnostics in
                if let diagnostics = diagnostics {
                    print(diagnostics.prettyJSON)
                } else {
                    print(["error": "no chat with that ID", "id": self.id].prettyJSON)
                }
                
                exit(0)
            }
        }
    }
    
    var children: [Routable] = [
        ChatDiagsCommand(), ChatListCommand(), MessagesCommand(), AccountsCommand()
    ]
}
