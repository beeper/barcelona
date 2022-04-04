//
//  StartNewChat.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 4/4/22.
//

import Foundation
import Barcelona
import Swog

public struct ResolveIdentifierCommand: Codable {
    public var identifier: String
}

public struct GUIDResponse: Codable {
    public var guid: String
    
    public init(_ guid: String) {
        self.guid = guid
    }
}

extension ResolveIdentifierCommand: Runnable {
    public func run(payload: IPCPayload) {
        ChatLocator.senderGUID(for: identifier).then { result in
            switch result {
            case .guid(let guid):
                payload.respond(.guid(.init(guid)))
            case .failed(let message):
                payload.fail(code: "err_destination_unreachable", message: message)
            }
        }
    }
}

public struct PrepareDMCommand: Codable {
    public var guid: String
}

extension PrepareDMCommand: Runnable {
    public func run(payload: IPCPayload) {
        let parsed = ParsedGUID(rawValue: guid)
        
        guard let service = parsed.service.flatMap(IMServiceStyle.init(rawValue:)) else {
            return payload.fail(code: "err_invalid_service", message: "The service provided does not exist.")
        }
        
        let chat = Chat.directMessage(withHandleID: parsed.last, service: service)
        CLInfo("PrepareDM", "Prepared chat \(chat.id) on service \(service.rawValue)")
        
        payload.respond(.ack)
    }
}
