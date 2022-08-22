//
//  MessageDataSource.swift
//  Barcelona
//
//  Created by Eric Rabil on 2/10/22.
//

import Foundation
import IMCore
import IMSharedUtilities
import IMFoundation

public protocol MessageDataSource {
    var id: String { get }
    var isFinished: Bool { get }
    var isSent: Bool { get }
    var isFromMe: Bool { get }
    var errorCode: FZErrorType { get }
}

extension IMMessage: MessageDataSource {
    public var errorCode: FZErrorType {
        _imMessageItem?.errorCode ?? .noError
    }
}
extension IMMessageItem: MessageDataSource {}
extension Message: MessageDataSource {
    public var errorCode: FZErrorType {
        failureCode
    }
}

public enum MessageSendProgress {
    case sending
    case sent
    case failed
    
    public init?(_ message: MessageDataSource) {
        guard message.isFromMe else {
            return nil
        }
        if message.isFinished {
            if message.isSent {
                self = .sent
            } else if message.errorCode != .noError {
                self = .failed
            } else {
                self = .sending
            }
        } else {
            self = .sending
        }
    }
}

public extension MessageDataSource {
    var sendProgress: MessageSendProgress? {
        MessageSendProgress(self)
    }
    
    var isSending: Bool {
        sendProgress == .sending
    }
    
    var isUnsent: Bool {
        sendProgress == .failed
    }
    
    func refreshedErrorCode() -> FZErrorType {
        BLLoadIMMessageItem(withGUID: id)?.errorCode ?? .noError
    }
}
