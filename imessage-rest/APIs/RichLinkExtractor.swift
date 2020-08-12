//
//  RichLinkExtractor.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation
import IMCore
import Vapor

class RichLinkExtractor {
    init(message: IMMessage, eventLoop: EventLoop) {
        self.message = message
        self.eventLoop = eventLoop
    }
    
    let eventLoop: EventLoop
    let message: IMMessage
    private var text: NSAttributedString { message.text }
    private var range: NSRange { NSRange(location: 0, length: text.length) }
    
    var messagesBySeparatingRichLinks: [IMMessage] {
        let text = self.text.mutableCopy() as! NSMutableAttributedString
        var messages: [IMMessage] = []
        
        text.enumerateAttribute(MessageAttributes.link, in: range, options: .init()) { value, range, bool in
            guard let url = value as? URL else { return }
            let substring = text.attributedSubstring(from: range)
            
            /** These links will just have the href attributes and no rich link data */
            if text.attribute(MessageAttributes.noRichLink, existsIn: range) {
                text.removeAttribute(MessageAttributes.noRichLink, range: range)
                return
            }
            
            let manager = IMBalloonPluginManager.sharedInstance()!
            
            /** Replaces the link in the plain string as it is becoming its own message */
            text.replaceCharacters(in: range, with: "")
            
            let guid = NSString.stringGUID()
            
            /** Construct plugin payload */
            let payload = IMPluginPayload()
            payload.messageGUID = guid
            payload.pluginBundleID = "com.apple.messages.URLBalloonProvider"
            payload.url = url
            
            let dataSource = manager.dataSource(forPluginPayload: payload) as! IMBalloonPluginDataSource
            /** Schedule rich link data to be loaded. Must be on main thread (I tried on other threads and would get EXC_BREAKPOINT, if anyone finds a solution lmk) */
            DispatchQueue.main.async {
                dataSource.payloadWillEnterShelf()
            }
            
            dataSource.payloadWillSendFromShelf()
            
            let payloadData = dataSource.messagePayloadDataForSending
            dataSource.payloadInShelf = false
            
            let sender = message.sender
            let time = message.time
            let expressiveSendStyleID = message.expressiveSendStyleID
            
            let newMessage = IMMessage.init(sender: sender, time: time, text: substring, messageSubject: nil, fileTransferGUIDs: nil, flags: FullFlagsFromMe.richLink.rawValue, error: nil, guid: guid, subject: message.subject, balloonBundleID: payload.pluginBundleID, payloadData: payloadData, expressiveSendStyleID: expressiveSendStyleID)!
            
            messages.append(newMessage)
        }
        
        if text.string.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
            message.text = text
            messages.append(message)
        }
        
        return messages
    }
}
