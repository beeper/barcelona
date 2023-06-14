//
//  CreatePluginMessage.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMDaemonCore
import IMFoundation
import IMSharedUtilities
import Logging
import Sentry

extension String {
    fileprivate func nsRange(of string: String) -> NSRange {
        (self as NSString).range(of: string)
    }
}

extension NSAttributedString {
    fileprivate func range(of string: String) -> NSRange {
        self.string.nsRange(of: string)
    }
}

public func ERCreateBlankRichLinkMessage(
    _ text: String,
    _ url: URL,
    _ initializer: (IMMessageItem) -> Void = { _ in }
) -> IMMessage {
    let messageItem = IMMessageItem.init(sender: nil, time: nil, guid: nil, type: 0)!

    messageItem.service = IMServiceStyle.iMessage.rawValue

    let messageString = NSMutableAttributedString(attributedString: .init(string: text))

    messageString.addAttributes(
        [
            MessageAttributes.writingDirection: -1,
            MessageAttributes.link: url,
        ],
        range: messageString.range(of: text)
    )

    messageItem.body = messageString
    messageItem.balloonBundleID = "com.apple.messages.URLBalloonProvider"
    messageItem.payloadData = Data()
    messageItem.flags = 5
    initializer(messageItem)

    return IMMessage.message(fromUnloadedItem: messageItem, service: .iMessage)!
}
