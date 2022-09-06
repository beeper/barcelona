//
//  IPCCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import Barcelona

public struct IPCError: Error {
    public let message: String?
    
    public init(_ message: String? = nil) {
        self.message = message
    }
    
    public var localizedDescription: String {
        self.message ?? "An unknown error occurred"
    }
}

import BarcelonaMautrixIPCProtobuf

public typealias IPCCommand = PBPayload.OneOf_Command
public typealias IPCPayload = PBPayload

public extension IPCPayload {
    func reply(withCommand command: IPCCommand) {
        guard id > 0 else {
            return CLDebug("Mautrix", "Reply issued for a command that had no ID. Inbound: %@ Outbound: %@", self.debugDescription, self.debugDescription)
        }
        BLWritePayload {
            $0.id = id
            $0.isResponse = true
            $0.command = command
        }
    }
    
    func reply(withResponse response: IPCResponse) {
        reply(withCommand: response)
    }
    
    func fail(code: String, message: String) {
        reply(withCommand: .error(.with {
            $0.code = code
            $0.message = message
        }))
    }
    
    func fail(strategy: ErrorStrategy) {
        reply(withCommand: strategy.asCommand)
    }
}
