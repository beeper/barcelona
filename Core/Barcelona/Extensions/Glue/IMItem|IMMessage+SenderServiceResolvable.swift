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
import IDS
import IMSharedUtilities

struct CBHandleFormatter {
    enum OutputFormat {
        case withResource
        case withoutResource
    }
    
    var format: OutputFormat
    
    static let prefixedFormatter = CBHandleFormatter(format: .withResource)
    static let unprefixedFormatter = CBHandleFormatter(format: .withoutResource)
    
    func format(_ id: String) -> String {
        // IDSDestination takes whatever you throw at it and parses it
        let destination = IDSDestination(uri: id)
        switch format {
        case .withResource: return destination.uri().prefixedURI
        case .withoutResource: return destination.uri().unprefixedURI
        }
    }
}

internal func CBResolveSenderHandle(originalHandle: String?, isFromMe: Bool, service: IMServiceStyle?) -> String? {
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
        _imMessageItem?.serviceStyle ?? CBResolveService(originalService: _imMessageItem?.serviceStyle, messageGUID: guid, type: _imMessageItem?.type ?? .message, chatID: chat)
    }
}

extension IMItem: SenderServiceResolvable {
    func resolveSenderID(inService service: IMServiceStyle? = nil) -> String? {
        CBResolveSenderHandle(originalHandle: sender, isFromMe: isFromMe, service: service ?? self.service?.service?.id)
    }
    
    func resolveServiceStyle(inChat chat: String?) -> IMServiceStyle {
        serviceStyle ?? CBResolveService(originalService: serviceStyle, messageGUID: guid, type: type, chatID: chat)
    }
}
