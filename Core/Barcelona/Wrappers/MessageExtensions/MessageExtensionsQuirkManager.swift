//
//  MessageExtensionsQuirkManager.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

#if false
func ERApplyMessageExtensionQuirks(
    toMessageItem messageItem: IMMessageItem,
    inChatID chatID: String,
    forOptions options: CreatePluginMessage
) {
    switch options.bundleID {
    case IMBalloonBundleIdentifierBusiness:
        IMSharedHelperReplaceExtensionPayloadDataWithFilePathForMessage(messageItem, chatID)

        break
    default:
        break
    }
}
#endif

func ERAttributedString(forExtensionOptions options: CreatePluginMessage) -> MessagePartParseResult {
    var parts: [MessagePart] = []

    if let attachmentID = options.attachmentID {
        parts.append(.init(type: .attachment, details: attachmentID))
    }

    return ERAttributedString(from: parts)
}
