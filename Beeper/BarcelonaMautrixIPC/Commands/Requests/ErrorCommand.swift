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
    case internal_error(String)
    
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
        case .internal_error(_):
            return "internal_error"
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
        case .internal_error(let error):
            return "Internal Error: \(error)"
        }
    }
    
    public var asCommand: IPCCommand {
        return .error(.with {
            $0.code = code
            $0.message = message
        })
    }
}
