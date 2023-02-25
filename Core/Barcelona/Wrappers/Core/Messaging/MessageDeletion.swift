//
//  MessageDeletion.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation
import IMCore

extension Chat {
    public func delete(messageID: String, parts: [Int]) -> Promise<Void> {
        let fullMessage = parts.count == 0

        return IMMessage.lazyResolve(withIdentifier: messageID)
            .then { message -> Void in
                guard let message = message else {
                    return
                }

                if fullMessage {
                    IMDaemonController.sharedInstance().deleteMessage(withGUIDs: [messageID], queryID: NSString.stringGUID())
                } else {
                    if let imChat = self.imChat, let chatItems = imChat.chatItems(for: [message._imMessageItem]) {
                        let items: [IMChatItem] = parts.compactMap {
                            if chatItems.count <= $0 { return nil }
                            return chatItems[$0]
                        }

                        let newItem = imChat.chatItemRules._item(
                            withChatItemsDeleted: items,
                            fromItem: message._imMessageItem
                        )

                        IMDaemonController.sharedInstance().updateMessage(newItem)
                    }
                }
            }
    }

    public func delete(messageID: String) -> Promise<Void> {
        delete(messageID: messageID, parts: [])
    }
}
