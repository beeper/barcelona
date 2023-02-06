//
//  SendMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

public struct SendMessageCommand: Codable, ChatResolvable {
    public var chat_guid: String
    public var text: String
    public var reply_to: String?
    public var reply_to_part: Int?
    public var rich_link: RichLinkMetadata?
    public var metadata: Message.Metadata?
}
