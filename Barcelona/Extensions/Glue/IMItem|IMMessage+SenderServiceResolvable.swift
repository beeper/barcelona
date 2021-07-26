//
//  IMItem|IMMessage+SenderServiceResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

internal func CBResolveSenderHandle(originalHandle: String?, isFromMe: Bool, service: IMServiceStyle?) -> String? {
    guard isFromMe, let service = service?.service else {
        return originalHandle
    }
    
    return Registry.sharedInstance.suitableHandle(for: service)?.idWithoutResource
}

internal func CBResolveService(originalService: IMServiceStyle?, type: Int64, chatID: String?) -> IMServiceStyle {
    if let service = originalService {
        return service
    }
    
    if type > 0 {
        return .iMessage
    } else {
        guard let chatID = chatID, let chat = IMChat.resolve(withIdentifier: chatID), let serviceStyle = chat.account?.service?.id else {
            return .SMS
        }
        
        return serviceStyle
    }
}

protocol SenderServiceResolvable {
    func resolveSenderID(inService service: IMServiceStyle?) -> String?
    func resolveServiceStyle(inChat chat: String?) -> IMServiceStyle
}

extension IMItem {
    var serviceStyle: IMServiceStyle? {
        service?.service?.id
    }
}

extension IMMessage: SenderServiceResolvable {
    func resolveSenderID(inService service: IMServiceStyle? = nil) -> String? {
        CBResolveSenderHandle(originalHandle: sender?.idWithoutResource, isFromMe: isFromMe, service: service ?? _imMessageItem?.serviceStyle)
    }
    
    func resolveServiceStyle(inChat chat: String?) -> IMServiceStyle {
        CBResolveService(originalService: _imMessageItem?.serviceStyle, type: _imMessageItem?.type ?? 0, chatID: chat)
    }
}

extension IMItem: SenderServiceResolvable {
    func resolveSenderID(inService service: IMServiceStyle? = nil) -> String? {
        CBResolveSenderHandle(originalHandle: sender, isFromMe: isFromMe, service: service ?? self.service?.service?.id)
    }
    
    func resolveServiceStyle(inChat chat: String?) -> IMServiceStyle {
        CBResolveService(originalService: serviceStyle, type: type, chatID: chat)
    }
}
