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
        let semaphore = DispatchSemaphore(value: 0)
        var retrievedGuid: GUIDResponse? = nil

        let promise = ChatLocator.senderGUID(for: identifier).then { result in
            switch result {
            case .guid(let guid):
                retrievedGuid = .init(guid)
            case .failed(let message):
                CLWarn("ResolveIdentifier", "Resolving identifier for \(identifier) failed with message: \(message)")
            }
            semaphore.signal()
        }

        // I don't know how promises ensure that they aren't deallocated and thus cancelled before completing (or if they do)
        // so we just ensure here the promise doesn't die before it could potentially complete
        withExtendedLifetime(promise) {
            let timeout = 12
            if semaphore.wait(timeout: .now() + .seconds(timeout)) != .success {
                CLWarn("ResolveIdentifier", "Resolving identifier for \(identifier) timed out in \(timeout) seconds")
            }
        }

        if let retrievedGuid {
            payload.respond(.guid(retrievedGuid), ipcChannel: ipcChannel)
        } else if IMServiceImpl.smsEnabled() {
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
