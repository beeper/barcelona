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

extension IMItem {
    var serviceStyle: IMServiceStyle? {
        service?.service?.id
    }
}

extension IMMessage {
    func resolveSenderID(inService service: IMServiceStyle? = nil) -> String? {
        CBResolveSenderHandle(originalHandle: sender?.idWithoutResource, isFromMe: isFromMe, service: service ?? _imMessageItem?.serviceStyle)
    }
}

extension IMItem {
    func resolveSenderID(inService service: IMServiceStyle? = nil) -> String? {
        CBResolveSenderHandle(originalHandle: sender, isFromMe: isFromMe, service: service ?? self.service?.service?.id)
    }
}
