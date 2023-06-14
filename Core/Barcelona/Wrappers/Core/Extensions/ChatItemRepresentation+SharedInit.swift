//
//  ChatItem+SharedInit.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities

protocol IMCoreDataResolvable: NSObjectProtocol {
    var id: String { get }
    var isFromMe: Bool { get }
    var effectiveTime: Double { get }
    var threadIdentifier: String? { get }
    var threadOriginator: IMMessageItem? { get }
    var threadOriginatorID: String? { get }
}

private let sel_threadOriginator = Selector("threadOriginator")
private let sel_threadIdentifier = Selector("threadIdentifier")

extension IMCoreDataResolvable {
    public var threadIdentifier: String? {
        guard self.responds(to: sel_threadIdentifier) else {
            return nil
        }

        return self.perform(sel_threadIdentifier)?.takeUnretainedValue() as? String
    }

    public var threadOriginator: IMMessageItem? {
        guard self.responds(to: sel_threadOriginator) else {
            return nil
        }

        return self.perform(sel_threadOriginator)?.takeUnretainedValue() as? IMMessageItem
    }

    public var threadOriginatorID: String? {
        threadOriginator?.id
    }
}

extension IMItem: IMCoreDataResolvable {
    public var id: String { guid! }

    public var effectiveTime: Double {
        (self.time?.timeIntervalSince1970 ?? 0) * 1000
    }
}

extension IMTranscriptChatItem: IMCoreDataResolvable {
    private var reliableDate: Date? {
        switch self {
        case let item as IMMessageChatItem:
            return item.time ?? _item()?.time
        default:
            return transcriptDate ?? _item()?.time
        }
    }
    
    public var effectiveTime: Double {
        (reliableDate?.timeIntervalSince1970 ?? 0) * 1000
    }
}
