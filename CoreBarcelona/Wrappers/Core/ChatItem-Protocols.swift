//
//  ChatItem-Protocols.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public protocol ChatItemRepresentation: Codable, Identifiable {
    associatedtype IDValue = String?
    associatedtype TimeValue = Double?
    
    var id: IDValue { get set }
    var chatID: String? { get set }
    var fromMe: Bool? { get set }
    var time: Double? { get set }
}

protocol AssociatedChatItemRepresentation: ChatItemRepresentation {
    var associatedID: String { get set }
}

protocol ChatItemAcknowledgable: ChatItemRepresentation {
    var id: String? { get set }
    var acknowledgments: [AcknowledgmentChatItem]? { get set }
}
