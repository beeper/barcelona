//
//  ChatItem-Protocols.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor

enum ChatItemType: String, Codable {
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
    case groupTitle
}

extension ChatItemType: Content {
    
}

protocol ChatItemRepresentation: Content {
    var guid: String? { get set }
    var chatGroupID: String? { get set }
    var fromMe: Bool? { get set }
    var time: Double? { get set }
}

protocol ChatItemAcknowledgable: ChatItemRepresentation {
    var acknowledgments: [AcknowledgmentChatItemRepresentation]? { get set }
}
