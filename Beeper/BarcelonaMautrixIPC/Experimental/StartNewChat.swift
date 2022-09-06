//
//  StartNewChat.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 4/4/22.
//

import Foundation
import Barcelona
import Swog
import Sentry
import BarcelonaMautrixIPCProtobuf

public typealias ResolveIdentifierCommand = PBResolveIdentifierRequest

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
            case .guid(let service, let localID):
                payload.respond(.guid(.with {
                    $0.service = service
                    $0.isGroup = false
                    $0.localID = localID
                }))
            case .failed(let message):
                payload.fail(code: "err_destination_unreachable", message: message)
            }
        }
    }
}

public typealias PrepareDMCommand = PBPrepareDMRequest

extension PrepareDMCommand: Runnable {
    public func run(payload: IPCPayload) {
        let transaction = SentrySDK.startTransaction(name: "prepare_dm", operation: "prepare_dm")
        
        if MXFeatureFlags.shared.mergedChats {
            let chat = Chat.directMessage(withHandleID: guid.localID, service: .iMessage)
            CLInfo("PrepareDM", "Prepared chat \(chat.id)")
        } else {
            guard let service = IMServiceStyle(rawValue: guid.service) else {
                transaction.setData(value: "err_invalid_service", key: "error")
                return payload.fail(code: "err_invalid_service", message: "The service provided does not exist.")
            }
            
            let chat = Chat.directMessage(withHandleID: guid.localID, service: service)
            CLInfo("PrepareDM", "Prepared chat \(chat.id) on service \(service.rawValue)")
        }
        
        payload.respond(.ack(true))
        transaction.finish(status: .ok)
    }
}
