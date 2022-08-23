//
//  IMChat+QuerySpecifiers.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/26/21.
//

import Foundation
import IMCore
import IMFoundation
import IMSharedUtilities

private extension IMChatRegistry {
    func __cb_allGUIDs(forChat chat: IMChat) -> [String] {
        if self.responds(to: Selector("allGUIDsForChat:")) {
            return allGUIDs(forChat: chat)
        } else if self.responds(to: Selector("_allGUIDsForChat:")) {
            return _allGUIDs(forChat: chat)
        } else if self.responds(to: Selector("_chatGUIDToChatMap")) {
            return _chatGUIDToChatMap().compactMap { id, chatCompare in
                guard chat == chatCompare else {
                    return nil
                }
                
                return id
            }
        } else if self.responds(to: Selector("chatGUIDToChatMap")) {
            return chatGUIDToChatMap().compactMap { id, chatCompare in
                guard chat == chatCompare else {
                    return nil
                }
                
                return id
            }
        } else {
            fatalError()
        }
    }
}

public extension IMChat {
    // Reconstruction of subroutine from IMCore that returns all chat identifiers and services to be used in IMDPersistence queries
    var querySpecifiers: (identifiers: [String], services: [String]) {
        let mergeCentrics = IMSharedHelperPersonCentricMergingEnabled() // dunno what this is but we'll respect it
        
        var pairs: Set<IMPair<NSString, NSString>> = Set() // IMPair produces a combinant hashable value suitable for deduping a pair of values
        
        if mergeCentrics || !isSingle {
            let guids = IMChatRegistry.shared.__cb_allGUIDs(forChat: self) // for a group chat, or for merging centrics, we can just use the GUIDs that the chat registry provides
            
            for guid in guids {
                var chatIdentifier: NSString?, service: NSString?, style = IMChatStyle.instantMessage
                
                IMComponentsFromChatGUID(guid, &chatIdentifier, &service, &style) // extract the chat identifier and service from the GUID and insert into the pairs
                
                if let chatIdentifier = chatIdentifier, let service = service {
                    pairs.insert(IMPair(first: chatIdentifier, second: service))
                }
            }
        } else {
            let participants = participants!
            
            for participant in participants {
                let siblings = participant.siblings!
                
                // enumerate all variants of the handle and append it to pairs. variants can be their aliases or their different services
                for sibling in siblings {
                    pairs.insert(IMPair(first: sibling.id as NSString, second: sibling.service.internalName as NSString))
                }
            }
        }
        
        return pairs.reduce(into: (identifiers: [String](), services: [String]())) { collector, pair in
            collector.identifiers.append(pair.first as String)
            collector.services.append(pair.second as String)
        }
    }
}
