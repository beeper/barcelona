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
    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel, chatRegistry _: CBChatRegistry) async {
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": String(describing: payload.id),
                    "command": payload.command.name.rawValue,
                ],
                key: "payload"
            )
        }
        let span = SentrySDK.startTransaction(name: "ResolveIdentifierCommand", operation: "run", bindToScope: true)
        let breadcrumb = Breadcrumb(level: .debug, category: "command")
        breadcrumb.message = "ResolveIdentifierCommand/\(payload.id ?? 0)/\(payload.id ?? 0)"
        breadcrumb.type = "user"
        SentrySDK.addBreadcrumb(breadcrumb)
        let log = Logger(label: "ResolveIdentifierCommand")
        var retrievedGuid: GUIDResponse? = nil

        let result: ChatLocator.SenderGUIDResult

        do {
            result = try await withThrowingTaskGroup(of: ChatLocator.SenderGUIDResult.self) { group in
                group.addTask {
                    try await ChatLocator.senderGUID(for: identifier)
                }
                group.addTask {
                    let timeout: UInt64 = 30
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
            log.info(
                "Responding that \(identifier) is available on \(retrievedGuid.guid)",
                source: "ResolveIdentifier"
            )
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
            log.info(
                "Responding that \(identifier) is unavailable",
                source: "ResolveIdentifier"
            )
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
    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel, chatRegistry _: CBChatRegistry) async {
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": String(describing: payload.id),
                    "command": payload.command.name.rawValue,
                ],
                key: "payload"
            )
        }
        let span = SentrySDK.startTransaction(name: "PrepareDMCommand", operation: "run", bindToScope: true)
        let breadcrumb = Breadcrumb(level: .debug, category: "command")
        breadcrumb.message = "PrepareDMCommand/\(payload.id ?? 0)"
        breadcrumb.type = "user"
        SentrySDK.addBreadcrumb(breadcrumb)
        let log = Logger(label: "PrepareDMCommand")

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

public struct PrepareGroupChatCommand: Codable, Runnable {
    public var guids: [String]

    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel, chatRegistry _: CBChatRegistry) async {
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": String(describing: payload.id),
                    "command": payload.command.name.rawValue,
                ],
                key: "payload"
            )
        }
        let span = SentrySDK.startTransaction(name: "PrepareGroupChatCommand", operation: "run", bindToScope: true)
        let breadcrumb = Breadcrumb(level: .debug, category: "command")
        breadcrumb.message = "PrepareGroupChatCommand/\(payload.id ?? 0)"
        breadcrumb.type = "user"
        SentrySDK.addBreadcrumb(breadcrumb)
        let log = Logger(label: "PrepareGroupChatCommand")

        let parsed = guids.map(ParsedGUID.init(rawValue:))
        let services = parsed.map { $0.service.flatMap(IMServiceStyle.init(rawValue:)) }

        guard !services.contains(where: { $0 == nil }) else {
            payload.fail(
                code: "err_invalid_service",
                message: "One or more of the provided services do not exist",
                ipcChannel: ipcChannel
            )
            span.finish(status: .invalidArgument)
            return
        }

        let service: IMServiceStyle = services.allSatisfy { $0 == .iMessage } ? .iMessage : .SMS

        let chat = await Chat.groupChat(withHandleIDs: parsed.map(\.last), service: service)
        log.info("Prepared chat \(chat.id) on service \(service.rawValue)", source: "PrepareGroupChatCommand")

        payload.respond(.ack, ipcChannel: ipcChannel)
        span.finish()
    }
}
