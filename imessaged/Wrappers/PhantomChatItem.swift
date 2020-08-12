//
//  PhantomChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation


//class PhantomChatItem: ChatItem<StubChatItemRepresentation> {
//    init(backing: NSObject, chatGUID: String) {
//        self.backing = backing
//        self.chatGUID = chatGUID
//        super.init(.phantom)
//    }
//    
//    let backing: NSObject
//    let chatGUID: String
//    
//    override var json: JSON {
//        switch (backing) {
//        case let backing as IMTranscriptChatItem:
//            return createChatItemJSON(item: backing, type: .phantom, chatGUID: chatGUID, extraData: ["className": backing.className])
//        case let backing as IMMessageItem:
//            return createItemJSON(item: backing, type: .phantom, chatGUID: chatGUID, extraData: ["className": backing.className])
//        default:
//            return ["chatGUID": chatGUID, "className": backing.className, "type": ChatItemType.phantom.rawValue]
//        }
//    }
//}
