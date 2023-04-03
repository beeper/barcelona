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
}

extension IMTranscriptChatItem: IMCoreDataResolvable {}
