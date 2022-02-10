//
//  MessageDataSource.swift
//  Barcelona
//
//  Created by Eric Rabil on 2/10/22.
//

import Foundation
import IMCore

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
            } else {
                self = .failed
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
    
    func refreshedErrorDescription() -> String? {
        switch refreshedErrorCode() {
        case .noError:
            return nil
        case .cancelled:
            return "Your message was interrupted while being sent."
        case .timeout:
            return "Your message took too long to send."
        case .networkFailure, .networkLookupFailure, .networkConnectionFailure, .noNetworkFailure, .networkBusyFailure, .networkDeniedFailure:
            return "Your message couldn't be sent due to a network connectivity issue."
        case .serverSignatureError:
            return "A secure connection cannot be established with iMessage, so your message will not be sent."
        case .serverDecodeError, .serverParseError, .serverInternalError, .serverInvalidRequestError, .serverMalformedRequestError, .serverUnknownRequestError, .serverRejectedError:
            return "The iMessage servers are having some trouble, please try again later."
        case .serverInvalidTokenError:
            return "The iMessage servers are rejecting your token. You may have to sign out and sign back in."
        case .remoteUserInvalid:
            return "The address you are trying to send a message to is invalid."
        case .remoteUserDoesNotExist:
            return "The address you are trying to send a message to is not registered for this service."
        case .remoteUserIncompatible:
            return "The address you are trying to send a message to cannot be reached using this mechanism."
        case .remoteUserRejected:
            return "The address you are trying to send a message to is rejecting your message."
        case .transcodingFailure:
            return "Your attachment failed to transcode."
        case .encryptionFailure, .otrEncryptionFailure:
            return "Your message couldn't be sent due to an iMessage encryption error."
        case .decryptionFailure, .otrDecryptionFailure:
            return "Your message couldn't be sent due to an iMessage decryption error."
        case .localAccountDisabled, .localAccountDoesNotExist, .localAccountNeedsUpdate, .localAccountInvalid, .invalidLocalCredentials:
            return "Your message coulnd't be sent due to an issue with your account. You may have to sign out and sign back in."
        case .attachmentUploadFailure, .attachmentDownloadFailure, .messageAttachmentUploadFailure, .messageAttachmentDownloadFailure:
            return "Your message couldn't be sent because your attachment failed to upload to iMessage."
        case .systemNeedsUpdate:
            return "Your message couldn't be sent because the system iMessage is running on is too outdated."
        case .serviceCrashed:
            return "Your message couldn't be sent because imagent is crashing."
        case .attachmentDownloadFailureFileNotFound:
            return "The attachment couldn't be downloaded because it is no longer available."
        case .textRenderingPreflightFailed:
            return "The message couldn't be processed because it is corrupted."
        case .unknownError, .sendFailed, .internalFailure:
            fallthrough
        @unknown default:
            return "Your message couldn't be sent due to an unknown error."
        }
    }
}
