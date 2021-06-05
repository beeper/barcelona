//
//  ErrorCommand.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/25/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct ErrorCommand: Codable {
    public var code: String
    public var message: String
}

public enum ErrorStrategy {
    case not_found
    case chat_not_found
    case contact_not_found
    case command_not_found(String)
    
    public var code: String {
        switch self {
        case .chat_not_found:
            fallthrough
        case .contact_not_found:
            fallthrough
        case .not_found:
            return "not_found"
        case .command_not_found(_):
            return "unknown_command"
        }
    }
    
    public var message: String {
        switch self {
        case .not_found:
            return "That resource does not exist"
        case .chat_not_found:
            return "That chat does not exist"
        case .contact_not_found:
            return "That contact does not exist"
        case .command_not_found(let command):
            return "Unknown command ".appendingFormat("'%@'", command)
        }
    }
    
    public var asCommand: IPCCommand {
        return .error(.init(code: code, message: message))
    }
}
