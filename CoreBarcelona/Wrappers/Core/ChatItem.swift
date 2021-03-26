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
    
    public var messageValue: Message? {
        guard case .message(let message) = self else {
            return nil
        }
        return message
    }
}
