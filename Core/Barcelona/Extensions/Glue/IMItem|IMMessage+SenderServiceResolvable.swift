//
//  IMItem|IMMessage+SenderServiceResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import BarcelonaDB

internal func CBResolveSenderHandle(originalHandle: String?, isFromMe: Bool, service: IMServiceStyle?, chat chatID: String?) -> String? {
    if !isFromMe, let chatID = chatID, let chat = IMChat.resolve(withIdentifier: chatID), let recipient = chat.recipient {
        // coerces messages sent from different handles into the original handle of the chat
        return recipient.idWithoutResource
    }
    
    guard isFromMe, let service = service?.service else {
        return originalHandle
    }
    
    switch service.id {
    case .iMessage:
        return nil
    case .FaceTime:
        return nil
    default:
        return Registry.sharedInstance.suitableHandle(for: service)?.idWithoutResource
    }
}

/// Synchronously resolves the service a message came from. Only call this if you really need to, pull from other sources of truth first.
internal func CBResolveMessageService(guid: String) -> IMServiceStyle {
    DBReader.shared.rawService(forMessage: guid)?.service?.id ?? .SMS
}

internal func CBResolveService(originalService: IMServiceStyle?, messageGUID: String, type: IMItemType, chatID: String?) -> IMServiceStyle {
    if let service = originalService {
        return service
    }
    
    if type != .message {
        return .iMessage
    } else {
        guard let chatID = chatID, let chat = IMChat.resolve(withIdentifier: chatID), let serviceStyle = chat.account?.service?.id else {
            return CBResolveMessageService(guid: messageGUID)
        }
        
        return serviceStyle
    }
}

protocol SenderServiceResolvable {
    func resolveSenderID(inService service: IMServiceStyle?, chat: String?) -> String?
    func resolveServiceStyle(inChat chat: String?) -> IMServiceStyle
}

extension IMItem {
    var serviceStyle: IMServiceStyle? {
        service?.service?.id
    }
}

extension IMMessage: SenderServiceResolvable {
    func resolveSenderID(inService service: IMServiceStyle? = nil, chat: String? = nil) -> String? {
        CBResolveSenderHandle(originalHandle: sender?.idWithoutResource, isFromMe: isFromMe, service: service ?? _imMessageItem?.serviceStyle, chat: chat)
    }
    
    func resolveServiceStyle(inChat chat: String?) -> IMServiceStyle {
        _imMessageItem?.serviceStyle ?? CBResolveService(originalService: _imMessageItem?.serviceStyle, messageGUID: guid, type: _imMessageItem?.type ?? .message, chatID: chat)
    }
}

extension IMItem: SenderServiceResolvable {
    func resolveSenderID(inService service: IMServiceStyle? = nil, chat: String? = nil) -> String? {
        CBResolveSenderHandle(originalHandle: sender, isFromMe: isFromMe, service: service ?? self.service?.service?.id, chat: chat)
    }
    
    func resolveServiceStyle(inChat chat: String?) -> IMServiceStyle {
        serviceStyle ?? CBResolveService(originalService: serviceStyle, messageGUID: guid, type: type, chatID: chat)
    }
}
