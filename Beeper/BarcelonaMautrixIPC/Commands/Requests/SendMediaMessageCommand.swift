//
//  SendMediaMessageCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import enum Swog.MetadataValue

public struct SendMediaMessageCommand: Codable, ChatResolvable, SendMessageCommandBase {
    public var chat_guid: String
    public var path_on_disk: String
    public var file_name: String
    public var mime_type: String
    public var reply_to: String?
    public var reply_to_part: Int?
    public var is_audio_message: Bool?
    public var metadata: MetadataValue?
}
