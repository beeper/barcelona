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
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        let span = SentrySDK.startTransaction(name: "ResolveIdentifierCommand", operation: "run", bindToScope: true)
        let log = Logger(label: "ResolveIdentifierCommand")
        var retrievedGuid: GUIDResponse? = nil

        let result: ChatLocator.SenderGUIDResult

        do {
            result = try await withThrowingTaskGroup(of: ChatLocator.SenderGUIDResult.self) { group in
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
        } catch {
            result = .failed("TaskGroup threw an error: \(error.localizedDescription)")
            SentrySDK.capture(error: error)
            span.finish(status: .internalError)
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
            span.finish()
        } else if IMServiceImpl.smsEnabled() {
            log.info(
                "Responding that \(identifier) is available on SMS due to availability of forwarding",
                source: "ResolveIdentifier"
            )
            payload.respond(.guid(.init("SMS;-;\(identifier)")), ipcChannel: ipcChannel)
            span.finish()
        } else {
            payload.fail(
                code: "err_destination_unreachable",
                message: "Identifier resolution failed and SMS service is unavailable",
                ipcChannel: ipcChannel
            )
            span.finish(status: .internalError)
        }
    }
}

public struct PrepareDMCommand: Codable {
    public var guid: String
}

extension PrepareDMCommand: Runnable {
    public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) async {
        let span = SentrySDK.startTransaction(name: "PrepareDMCommand", operation: "run", bindToScope: true)
        let log = Logger(label: "ResolveIdentifierCommand")

        let parsed = ParsedGUID(rawValue: guid)

        guard let service = parsed.service.flatMap(IMServiceStyle.init(rawValue:)) else {
            payload.fail(
                code: "err_invalid_service",
                message: "The service provided does not exist.",
                ipcChannel: ipcChannel
            )
            span.finish(status: .invalidArgument)
            return
        }

        let chat = await Chat.directMessage(withHandleID: parsed.last, service: service)
        log.info("Prepared chat \(chat.id) on service \(service.rawValue)", source: "PrepareDM")

        payload.respond(.ack, ipcChannel: ipcChannel)
        span.finish()
    }
}
