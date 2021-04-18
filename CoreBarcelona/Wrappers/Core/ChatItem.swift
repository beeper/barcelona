//
//  ChatItemV2.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/1/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public struct BulkChatItemRepresentation: Codable {
    public init(items: [ChatItem]) {
        self.items = items
    }
    
    public var items: [ChatItem]
}

/// Container for all possible items
public indirect enum ChatItem {
    case date(_ item: DateItem)
    case sender(_ item: SenderItem)
    case participantChange(_ item: ParticipantChangeItem)
    case attachment(_ item: AttachmentChatItem)
    case status(_ item: StatusChatItem)
    case groupAction(_ item: GroupActionItem)
    case plugin(_ item: PluginChatItem)
    case text(_ item: TextChatItem)
    case acknowledgment(_ item: AcknowledgmentChatItem)
    case associated(_ item: AssociatedMessageItem)
    case message(_ item: Message)
    case phantom(_ item: PhantomChatItem)
    case groupTitle(_ item: GroupTitleChangeItem)
    case typing(_ item: TypingItem)
    case sticker(_ item: StickerChatItem)
    case action(_ item: ActionChatItem)
    
    public var id: String? {
        switch self {
        case .date(let item):
            return item.id
        case .sender(let item):
            return item.id
        case .participantChange(let item):
            return item.id
        case .attachment(let item):
            return item.id
        case .status(let item):
            return item.id
        case .groupAction(let item):
            return item.id
        case .plugin(let item):
            return item.id
        case .text(let item):
            return item.id
        case .acknowledgment(let item):
            return item.id
        case .associated(let item):
            return item.id
        case .message(let item):
            return item.id
        case .phantom(let item):
            return item.id
        case .groupTitle(let item):
            return item.id
        case .typing(let item):
            return item.id
        case .sticker(let item):
            return item.id
        case .action(let item):
            return item.id
        }
    }
    
    public var sender: String? {
        get {
            switch self {
            case .groupAction(let item):
                return item.sender
            case .acknowledgment(let item):
                return item.sender
            case .message(let item):
                return item.sender
            case .groupTitle(let item):
                return item.sender
            case .typing(let item):
                return item.sender
            case .action(let item):
                return item.sender
            default:
                return nil
            }
        }
        set {
            switch self {
            case .groupAction(var item):
                item.sender = newValue
                self = .groupAction(item)
            case .acknowledgment(var item):
                item.sender = newValue
                self = .acknowledgment(item)
            case .message(var item):
                item.sender = newValue
                self = .message(item)
            case .groupTitle(var item):
                item.sender = newValue
                self = .groupTitle(item)
            case .typing(var item):
                item.sender = newValue
                self = .typing(item)
            case .action(var item):
                item.sender = newValue
                self = .action(item)
            default:
                return
            }
        }
    }
    
    public var messageValue: Message? {
        guard case .message(let message) = self else {
            return nil
        }
        return message
    }
}
