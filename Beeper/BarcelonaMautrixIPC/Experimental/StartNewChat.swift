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
import IMCore

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
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        do {
            let result = try ChatLocator.senderGUID(for: identifier).wait(upTo: .now() + .seconds(20))
            switch result {
            case .guid(let guid):
                payload.respond(.guid(.init(guid)), ipcChannel: ipcChannel)
                return
            case .failed(let message):
                CLWarn("ResolveIdentifier", "Resolving identifier for \(identifier) failed with message: \(message)")
            }
        } catch {
            CLWarn("ResolveIdentifier", "Resolving identifier for \(identifier) timed out in 20 seconds")
        }

        if IMServiceImpl.smsEnabled() {
            CLInfo("ResolveIdentifier", "Responding that \(identifier) is available on SMS due to availability of forwarding")
            payload.respond(.guid(.init("SMS;-;\(identifier)")), ipcChannel: ipcChannel)
        } else {
            payload.fail(code: "err_destination_unreachable", message: "Identifier resolution failed and SMS service is unavailable", ipcChannel: ipcChannel)
        }
    }
}

public struct PrepareDMCommand: Codable {
    public var guid: String
}

extension PrepareDMCommand: Runnable {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        let transaction = SentrySDK.startTransaction(name: "prepare_dm", operation: "prepare_dm")
        
        let parsed = ParsedGUID(rawValue: guid)
        
        if MXFeatureFlags.shared.mergedChats {
            let chat = Chat.directMessage(withHandleID: parsed.last, service: .iMessage)
            CLInfo("PrepareDM", "Prepared chat \(chat.id)")
        } else {
            guard let service = parsed.service.flatMap(IMServiceStyle.init(rawValue:)) else {
                transaction.setData(value: "err_invalid_service", key: "error")
                return payload.fail(code: "err_invalid_service", message: "The service provided does not exist.", ipcChannel: ipcChannel)
            }
            
            let chat = Chat.directMessage(withHandleID: parsed.last, service: service)
            CLInfo("PrepareDM", "Prepared chat \(chat.id) on service \(service.rawValue)")
        }
        
        payload.respond(.ack, ipcChannel: ipcChannel)
        transaction.finish(status: .ok)
    }
}
