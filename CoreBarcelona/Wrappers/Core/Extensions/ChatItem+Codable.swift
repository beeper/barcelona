//
//  ChatItem+Codable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

extension ChatItem: Codable {
    // MARK: - ChatItem coding type identifier
    private enum ChatItemType: String, Codable, CodingKey {
        case status
        case attachment
        case participantChange
        case sender
        case date
        case message
        case associated
        case groupAction
        case plugin
        case text
        case phantom
        case typing
        case acknowledgment
        case sticker
        case groupTitle
        case action
    }
    
    /// Returns the identifiable type for the item
    private var type: ChatItemType {
        switch self {
        case .date(_):
            return .date
        case .sender(_):
            return .sender
        case .participantChange(_):
            return .participantChange
        case .attachment(_):
            return .attachment
        case .status(_):
            return .status
        case .groupAction(_):
            return .groupAction
        case .plugin(_):
            return .plugin
        case .text(_):
            return .text
        case .acknowledgment(_):
            return .acknowledgment
        case .associated(_):
            return .associated
        case .message(_):
            return .message
        case .phantom(_):
            return .phantom
        case .groupTitle(_):
            return .groupTitle
        case .typing(_):
            return .typing
        case .sticker(_):
            return .sticker
        case .action(_):
            return .action
        }
    }
    
    // MARK: Codable
    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let itemType = try container.decode(ChatItemType.self, forKey: .type)
        
        switch itemType {
        case .date:
            self = .date(try container.decode(DateItem.self, forKey: .payload))
        case .sender:
            self = .sender(try container.decode(SenderItem.self, forKey: .payload))
        case .participantChange:
            self = .participantChange(try container.decode(ParticipantChangeItem.self, forKey: .payload))
        case .attachment:
            self = .attachment(try container.decode(AttachmentChatItem.self, forKey: .payload))
        case .status:
            self = .status(try container.decode(StatusChatItem.self, forKey: .payload))
        case .groupAction:
            self = .groupAction(try container.decode(GroupActionItem.self, forKey: .payload))
        case .plugin:
            self = .plugin(try container.decode(PluginChatItem.self, forKey: .payload))
        case .text:
            self = .text(try container.decode(TextChatItem.self, forKey: .payload))
        case .acknowledgment:
            self = .acknowledgment(try container.decode(AcknowledgmentChatItem.self, forKey: .payload))
        case .associated:
            self = .associated(try container.decode(AssociatedMessageItem.self, forKey: .payload))
        case .message:
            self = .message(try container.decode(Message.self, forKey: .payload))
        case .phantom:
            self = .phantom(try container.decode(PhantomChatItem.self, forKey: .payload))
        case .groupTitle:
            self = .groupTitle(try container.decode(GroupTitleChangeItem.self, forKey: .payload))
        case .typing:
            self = .typing(try container.decode(TypingItem.self, forKey: .payload))
        case .sticker:
            self = .sticker(try container.decode(StickerChatItem.self, forKey: .payload))
        case .action:
            self = .action(try container.decode(ActionChatItem.self, forKey: .payload))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.type, forKey: .type)
        
        switch self {
        case .date(let item):
            try container.encode(item, forKey: .payload)
        case .sender(let item):
            try container.encode(item, forKey: .payload)
        case .participantChange(let item):
            try container.encode(item, forKey: .payload)
        case .attachment(let item):
            try container.encode(item, forKey: .payload)
        case .status(let item):
            try container.encode(item, forKey: .payload)
        case .groupAction(let item):
            try container.encode(item, forKey: .payload)
        case .plugin(let item):
            try container.encode(item, forKey: .payload)
        case .text(let item):
            try container.encode(item, forKey: .payload)
        case .acknowledgment(let item):
            try container.encode(item, forKey: .payload)
        case .associated(let item):
            try container.encode(item, forKey: .payload)
        case .message(let item):
            try container.encode(item, forKey: .payload)
        case .phantom(let item):
            try container.encode(item, forKey: .payload)
        case .groupTitle(let item):
            try container.encode(item, forKey: .payload)
        case .typing(let item):
            try container.encode(item, forKey: .payload)
        case .sticker(let item):
            try container.encode(item, forKey: .payload)
        case .action(let item):
            try container.encode(item, forKey: .payload)
        }
    }
}
