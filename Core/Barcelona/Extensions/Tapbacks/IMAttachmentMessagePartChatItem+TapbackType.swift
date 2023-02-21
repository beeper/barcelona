//
//  Image+Resize.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif

enum TapBackSpecificItemType: UInt8 {
    case attachment = 0
    case text = 1
    case audioMessage = 2
    case image = 3
    case contact = 4
    case event = 5
    case location = 6
    case movie = 7
    case walletPass = 8
    case plugin = 9
}

extension IMAttachmentMessagePartChatItem {
    /**
     Computed type representing this attachment
     */
    var tapBackType: TapBackSpecificItemType {
        guard let transferGUID = transferGUID,
            let transfer = IMFileTransferCenter.sharedInstance().transfer(forGUID: transferGUID)
        else { return .attachment }

        if let utType = transfer.type as CFString? {
            if isAudioMessage || UTTypeConformsTo(utType, kUTTypeAudio) { return .audioMessage }
            if UTTypeConformsTo(utType, kUTTypeImage) { return .image }
            if UTTypeConformsTo(utType, kUTTypeContact) { return .contact }
            if UTTypeConformsTo(utType, kUTTypeCalendarEvent) { return .event }
            if UTTypeConformsTo(utType, kUTTypeMovie) { return .movie }
        }
        if let mimeType = transfer.mimeType {
            if mimeType == "text/x-vlocation" { return .location }
            if mimeType == "application/vnd.apple.pkpass" { return .walletPass }
        }

        return .attachment
    }

    var isAudioMessage: Bool {
        message.isAudioMessage
    }
}
