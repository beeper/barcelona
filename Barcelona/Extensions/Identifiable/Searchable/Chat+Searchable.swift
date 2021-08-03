//
//  Chat+Searchable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

#if DEBUG
import os.log
#endif

public struct ChatSearchParameters: QueryParameters {
    public init(identifiers: [String]? = nil, participants: [String]? = nil, display_name: String? = nil, read_receipts: Bool? = nil, ignore_alerts: Bool? = nil, style: Int? = nil, join_state: Int? = nil, services: [IMServiceStyle]? = nil, has_unread: Bool? = nil, has_failed: Bool? = nil, last_message_text: String? = nil, limit: Int? = nil, page: Int? = nil) {
        self.identifiers = identifiers
        self.participants = participants
        self.display_name = display_name
        self.read_receipts = read_receipts
        self.ignore_alerts = ignore_alerts
        self.style = style
        self.join_state = join_state
        self.services = services
        self.has_unread = has_unread
        self.has_failed = has_failed
        self.last_message_text = last_message_text
        self.limit = limit
        self.page = page
    }
    
    /// Narrow the results to a subset of chat identifiers
    public var identifiers: [String]?
    /// Narrow the results to a subset of participants
    public var participants: [String]?
    /// Narrow the results to chats with display names containing the given text, case insensitive
    public var display_name: String?
    /// Narrow the results to chats with the given read receipt state
    public var read_receipts: Bool?
    /// Narrow the results to chats with the given DND state
    public var ignore_alerts: Bool?
    /// Narrow the results to chats with the given style
    public var style: Int?
    /// Narrow the results to chats with the given join state
    public var join_state: Int?
    /// Narrow the results to chats with the given service
    public var services: [IMServiceStyle]?
    /// Narrow the results to chats with unread messages
    public var has_unread: Bool?
    /// Narrow the results to chats with failed messages
    public var has_failed: Bool?
    /// Narrow the results to chats with the last message text containing a given string
    public var last_message_text: String?
    /// Max number of results to return
    public var limit: Int?
    public var page: Int?
    
    fileprivate var parameters: [ChatSearchParameter] {
        var parameters: [ChatSearchParameter] = []
        
        if let identifiers = identifiers {
            parameters.append(.identifiers(identifiers))
        }
        
        if let participants = participants {
            parameters.append(.participants(participants))
        }
        
        if let displayName = display_name {
            parameters.append(.displayName(displayName.lowercased()))
        }
        
        if let readReceipts = read_receipts {
            parameters.append(.readReceipts(readReceipts))
        }
        
        if let ignoreAlerts = ignore_alerts {
            parameters.append(.ignoreAlerts(ignoreAlerts))
        }
        
        if let style = style {
            parameters.append(.style(style))
        }
        
        if let joinState = join_state {
            parameters.append(.joinState(joinState))
        }
        
        if let services = services {
            parameters.append(.services(services))
        }
        
        if let hasUnread = has_unread {
            parameters.append(.hasUnread(hasUnread))
        }
        
        if let hasFailed = has_failed {
            parameters.append(.hasFailed(hasFailed))
        }
        
        if let lastMessageText = last_message_text {
            parameters.append(.lastMessageText(lastMessageText.lowercased()))
        }
        
        return parameters
    }
}

private extension IMChat {
    var handleIDs: [String] {
        participants.map(\.id)
    }
}

private enum ChatSearchParameter {
    case identifiers([String])
    case participants([String])
    case displayName(String)
    case readReceipts(Bool)
    case ignoreAlerts(Bool)
    case style(Int)
    case joinState(Int)
    case services([IMServiceStyle])
    case hasUnread(Bool)
    case hasFailed(Bool)
    case lastMessageText(String)
}

extension ChatSearchParameter: SearchParameter {
    public func test(_ chat: IMChat) -> Bool {
        switch self {
        case .style(let style):
            if chat.chatStyle != style {
                return false
            }
        case .hasFailed(let failed):
            if failed {
                if chat.messageFailureCount == 0 {
                    return false
                }
            } else {
                if chat.messageFailureCount != 0 {
                    return false
                }
            }
        case .hasUnread(let unread):
            if unread {
                if chat.unreadMessageCount == 0 {
                    return false
                }
            } else {
                if chat.unreadMessageCount != 0 {
                    return false
                }
            }
        case .identifiers(let identifiers):
            if !identifiers.contains(chat.id) {
                return false
            }
        case .ignoreAlerts(let ignoreAlerts):
            if chat.ignoreAlerts != ignoreAlerts {
                return false
            }
        case .readReceipts(let readReceipts):
            if chat.readReceipts != readReceipts {
                return false
            }
        case .joinState(let joinState):
            if chat.joinState != joinState {
                return false
            }
        case .lastMessageText(let text):
            if !(chat.lastMessage?.text?.string.lowercased().contains(text) ?? false) {
                return false
            }
        case .participants(let participants):
            if !chat.handleIDs.contains(items: participants) {
                return false
            }
        case .services(let services):
            if !services.contains(chat.account.service.id) {
                return false
            }
        case .displayName(let displayName):
            if !(chat.displayName?.lowercased().contains(displayName) ?? false) {
                return false
            }
        }
        
        return true
    }
}

extension Array where Element : Equatable {
    func contains(items: [Element]) -> Bool {
        items.allSatisfy {
            self.contains($0)
        }
    }
}

extension Chat: Searchable {
    public static func resolve(withParameters rawParameters: ChatSearchParameters) -> Promise<[Chat]> {
        let parameters = rawParameters.parameters
        
        if parameters.count == 0 {
            return .success([])
        }
        
        #if DEBUG
        os_log("Performing chat search with parameters %@", parameters)
        #endif
        
        var chats = IMChatRegistry.shared.allChats.filter {
            parameters.test($0)
        }.map(\.representation)
        
        chats.sort { chat1, chat2 in
            chat1.lastMessageTime > chat2.lastMessageTime
        }
        
        if let limit = rawParameters.limit {
            chats = Array(chats.prefix(limit))
        }
        
        return .success(chats)
    }
}
