//
//  Chat.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Combine
import IMCore

import Vapor

enum ChatStyle: UInt8 {
    case group = 0x2b
    case single = 0x2d
}

class QueryFailedError: Error {
    init() {
        
    }
}

protocol BulkChatRepresentatable {
    var chats: [ChatRepresentation] { get set }
}

struct BulkChatRepresentation: Content, BulkChatRepresentatable {
    init(_ chats: [IMChat]) {
        self.chats = chats.map {
            ChatRepresentation($0)
        }
    }
    
    init(_ chats: ArraySlice<IMChat>) {
        self.chats = chats.map {
            ChatRepresentation($0)
        }
    }
    
    init(_ chats: [ChatRepresentation]) {
        self.chats = chats
    }
    
    var chats: [ChatRepresentation]
}

struct ChatIDRepresentation: Content {
    var chat: String
}

struct ChatRepresentation: Content {
    init(_ backing: IMChat) {
        guid = backing.guid
        joinState = backing.joinState
        roomName = backing.roomName
        displayName = backing.displayName
        groupID = backing.groupID
        participants = backing.participantHandleIDs() ?? []
        lastAddressedHandleID = backing.lastAddressedHandleID
        unreadMessageCount = backing.unreadMessageCount
        messageFailureCount = backing.messageFailureCount
        service = backing.account?.serviceName
        lastMessage = backing.lastMessage?.description(forPurpose: 0x2, inChat: backing, senderDisplayName: backing.lastMessage?.sender._displayNameWithAbbreviation)
        lastMessageTime = (backing.lastMessage?.time.timeIntervalSince1970 ?? 0) * 1000
        style = backing.chatStyle
    }
    
    var guid: String
    var joinState: Int64
    var roomName: String?
    var displayName: String?
    var groupID: String?
    var participants: [String]
    var lastAddressedHandleID: String?
    var unreadMessageCount: UInt64?
    var messageFailureCount: UInt64?
    var service: String?
    var lastMessage: String?
    var lastMessageTime: Double
    var style: UInt8
}

func chatToRepresentation(_ backing: IMChat, skinny: Bool = false) -> ChatRepresentation {
    return .init(backing)
}
