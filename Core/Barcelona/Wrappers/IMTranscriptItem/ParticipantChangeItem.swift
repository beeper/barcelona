//
//  ParticipantChangeChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

protocol IMParticipantChangeParseable: IMCoreDataResolvable {
    var initiatorID: String? { get }
    var targetID: String? { get }
    var changeType: Int64 { get }
}

extension IMParticipantChangeChatItem: IMParticipantChangeParseable {
    var initiatorID: String? {
        sender?.id
    }

    var targetID: String? {
        otherHandle?.id
    }
}

extension IMParticipantChangeItem: IMParticipantChangeParseable {
    var initiatorID: String? {
        sender
    }

    var targetID: String? {
        otherHandle
    }
}

public struct ParticipantChangeItem: ChatItem, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [
        IMParticipantChangeChatItem.self, IMParticipantChangeItem.self,
    ]

    public init?(ingesting item: NSObject, context: IngestionContext) {
        switch item {
        case let item as IMParticipantChangeChatItem:
            self.init(item, chatID: context.chatID)
        case let item as IMParticipantChangeItem:
            self.init(item, chatID: context.chatID)
        default:
            return nil
        }
    }

    init(_ item: IMParticipantChangeParseable, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
        initiatorID = item.initiatorID
        targetID = item.targetID
        changeType = item.changeType
    }

    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var initiatorID: String?
    public var targetID: String?
    public var changeType: Int64

    public var type: ChatItemType {
        .participantChange
    }
}
