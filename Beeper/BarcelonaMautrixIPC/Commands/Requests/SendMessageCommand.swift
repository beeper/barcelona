//
//  SendMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

public protocol SendMessageCommandBase {
    var chat_guid: String { get set }
    var reply_to: String? { get set }
    var reply_to_part: Int? { get set }
    var metadata: Message.Metadata? { get set }
}

public struct SendMessageCommand: Codable, ChatResolvable, SendMessageCommandBase {
    public var chat_guid: String
    public var text: String
    public var reply_to: String?
    public var reply_to_part: Int?
    public var rich_link: RichLinkMetadata?
    public var metadata: Message.Metadata?
}
