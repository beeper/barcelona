//
//  IMChatRegistry+LoadMessageWithGUID.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Logging

/// Provides various functions to aid in the lazy resolution of messages
extension IMChat {
    private func generateRulesIfNeeded() -> IMTranscriptChatItemRules {
        guard let rules = value(forKey: "_chatItemRules") as? IMTranscriptChatItemRules else {
            setValue(IMTranscriptChatItemRules()._init(withChat: self), forKey: "_chatItemRules")
            return generateRulesIfNeeded()
        }

        return rules
    }

    var chatItemRules: IMTranscriptChatItemRules {
        generateRulesIfNeeded()
    }
}
