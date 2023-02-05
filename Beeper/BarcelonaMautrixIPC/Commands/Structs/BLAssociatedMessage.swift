//
//  BLAssociatedMessage.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

class BLAssociatedMessage: Codable {
    init(target_guid: String, type: Int) {
        self.target_guid = target_guid
        self.type = type
    }
    
    var target_guid: String
    var type: Int
}

class BLTapback: BLAssociatedMessage {
    init(chat_guid: String, target_guid: String, target_part: Int, type: Int) {
        self.chat_guid = chat_guid
        self.target_part = target_part
        super.init(target_guid: target_guid, type: type)
    }
    
    private enum CodingKeys: CodingKey {
        case chat_guid, target_part
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        chat_guid = try container.decode(String.self, forKey: .chat_guid)
        target_part = try container.decode(Int.self, forKey: .target_part)
        
        try super.init(from: decoder)
    }
    
    var chat_guid: String
    var target_part: Int
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chat_guid, forKey: .chat_guid)
        try container.encode(target_part, forKey: .target_part)
    }
}
