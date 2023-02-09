//
//  StartNewChat.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 4/4/22.
//

import Barcelona
import Foundation
import IMCore
import Logging
import Sentry

public struct ResolveIdentifierCommand: Codable {
    public var identifier: String
}

public struct GUIDResponse: Codable {
    public var guid: String

    public init(_ guid: String) {
        self.guid = guid
    }
}

enum ResolveIdentifierCommandError: Error {
    case timeout
}

extension ResolveIdentifierCommand: Runnable {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        Task {
            let log = Logger(label: "ResolveIdentifierCommand")
            var retrievedGuid: GUIDResponse? = nil

            let result = try await withThrowingTaskGroup(of: ChatLocator.SenderGUIDResult.self) { group in
                group.addTask {
                    try await ChatLocator.senderGUID(for: identifier)
                }
                group.addTask {
                    let timeout: UInt64 = 12
                    try await Task.sleep(nanoseconds: timeout * 1_000_000_000)
                    log.warning(
                        "Resolving identifier for \(identifier) timed out in \(timeout) seconds",
                        source: "ResolveIdentifier"
                    )
                    throw ResolveIdentifierCommandError.timeout
                }
                let result = try await group.next()!
                group.cancelAll()
                return result
            }

            switch result {
            case .guid(let guid):
                retrievedGuid = .init(guid)
            case .failed(let message):
                log.warning(
                    "Resolving identifier for \(identifier) failed with message: \(message)",
                    source: "ResolveIdentifier"
                )
            }

            if let retrievedGuid {
                payload.respond(.guid(retrievedGuid), ipcChannel: ipcChannel)
            } else if IMServiceImpl.smsEnabled() {
                log.info(
                    "Responding that \(identifier) is available on SMS due to availability of forwarding",
                    source: "ResolveIdentifier"
                )
                payload.respond(.guid(.init("SMS;-;\(identifier)")), ipcChannel: ipcChannel)
            } else {
                payload.fail(
                    code: "err_destination_unreachable",
                    message: "Identifier resolution failed and SMS service is unavailable",
                    ipcChannel: ipcChannel
                )
            }
        }
    }
}

public struct PrepareDMCommand: Codable {
    public var guid: String
}

extension PrepareDMCommand: Runnable {
    @MainActor
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
        let log = Logger(label: "ResolveIdentifierCommand")

        let parsed = ParsedGUID(rawValue: guid)

        if MXFeatureFlags.shared.mergedChats {
            let chat = Chat.directMessage(withHandleID: parsed.last, service: .iMessage)
            log.info("Prepared chat \(chat.id)", source: "PrepareDM")
        } else {
            guard let service = parsed.service.flatMap(IMServiceStyle.init(rawValue:)) else {
                transaction.setData(value: "err_invalid_service", key: "error")
                return payload.fail(
                    code: "err_invalid_service",
                    message: "The service provided does not exist.",
                    ipcChannel: ipcChannel
                )
            }

            let chat = Chat.directMessage(withHandleID: parsed.last, service: service)
            log.info("Prepared chat \(chat.id) on service \(service.rawValue)", source: "PrepareDM")
        }

        payload.respond(.ack, ipcChannel: ipcChannel)
    }
}
