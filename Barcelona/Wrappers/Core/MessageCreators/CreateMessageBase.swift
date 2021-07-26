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
    var replyToPart: String? { get set }
    
    func imMessage(inChat chatIdentifier: String) -> Promise<IMMessage, Error>
    func parseToAttributed() -> Promise<MessagePartParseResult, Error>
    func createIMMessageItem(withThreadIdentifier threadIdentifier: String?, withChatIdentifier chatIdentifier: String, withParseResult parseResult: MessagePartParseResult) throws -> (IMMessageItem, NSMutableAttributedString?)
}

extension CreateMessageBase {
    func resolveThreadIdentifier() -> Promise<String?, Error> {
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            if let threadIdentifier = threadIdentifier {
                return .success(threadIdentifier)
            } else if let replyToPart = replyToPart {
                return IMChatItem.resolveThreadIdentifier(forIdentifier: replyToPart)
            }
        }
        return .success(nil)
    }
    
    func finalize(imMessageItem: IMMessageItem, withSubject subject: NSMutableAttributedString?) throws -> IMMessage {
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            imMessageItem.setThreadIdentifier(threadIdentifier)
        }
        
        guard let message = IMMessage.message(fromUnloadedItem: imMessageItem, withSubject: subject) else {
            throw BarcelonaError(code: 500, message: "Failed to construct IMMessage from IMMessageItem")
        }
        
        return message
    }
    
    public func imMessage(inChat chatIdentifier: String) -> Promise<IMMessage, Error> {
        resolveThreadIdentifier().then { threadIdentifier in
            parseToAttributed().map {
                (threadIdentifier, $0)
            }
        }.then { packed in
            let (imMessageItem, subject) = try createIMMessageItem(withThreadIdentifier: packed.0, withChatIdentifier: chatIdentifier, withParseResult: packed.1)
            
            imMessageItem.setValue(packed.1.transferGUIDs, forKey: "fileTransferGUIDs")
            imMessageItem.service = IMChat.resolve(withIdentifier: chatIdentifier)!.account.service.name
            
            return try finalize(imMessageItem: imMessageItem, withSubject: subject)
        }
    }
}

