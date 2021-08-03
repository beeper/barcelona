//
//  CreateMessageBase.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities

public protocol CreateMessageBase: Codable {
    var threadIdentifier: String? { get set }
    var replyToGUID: String? { get set }
    var replyToPart: Int? { get set }
    
    func imMessage(inChat chatIdentifier: String) throws -> IMMessage
    func parseToAttributed() -> MessagePartParseResult
    func createIMMessageItem(withThreadIdentifier threadIdentifier: String?, withChatIdentifier chatIdentifier: String, withParseResult parseResult: MessagePartParseResult) throws -> (IMMessageItem, NSMutableAttributedString?)
}

extension CreateMessageBase {
    var resolvedThreadIdentifier: String? {
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            if let threadIdentifier = threadIdentifier {
                return threadIdentifier
            } else if let replyToGUID = replyToGUID {
                return IMChatItem.resolveThreadIdentifier(forMessageWithGUID: replyToGUID, part: replyToPart ?? 0)
            }
        }
        return nil
    }
    
    func finalize(imMessageItem: IMMessageItem, withSubject subject: NSMutableAttributedString?) throws -> IMMessage {
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            imMessageItem.setThreadIdentifier(resolvedThreadIdentifier)
        }
        
        guard let message = IMMessage.message(fromUnloadedItem: imMessageItem, withSubject: subject) else {
            throw BarcelonaError(code: 500, message: "Failed to construct IMMessage from IMMessageItem")
        }
        
        return message
    }
    
    public func imMessage(inChat chatIdentifier: String) throws -> IMMessage {
        let parseResult = parseToAttributed()
        
        let (imMessageItem, subject) = try createIMMessageItem(withThreadIdentifier: nil, withChatIdentifier: chatIdentifier, withParseResult: parseResult)
        
        imMessageItem.setValue(parseResult.transferGUIDs, forKey: "fileTransferGUIDs")
        imMessageItem.service = IMChat.resolve(withIdentifier: chatIdentifier)!.account.service.name
        
        return try finalize(imMessageItem: imMessageItem, withSubject: subject)
    }
}

extension Promise {
    convenience init(_ cb: () throws -> Output) {
        self.init { resolve, reject in
            do {
                try resolve(cb())
            } catch {
                reject(error)
            }
        }
    }
}
