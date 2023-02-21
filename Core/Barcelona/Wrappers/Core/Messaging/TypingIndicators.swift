//
//  TypingIndicators.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation

extension Chat {
    public var isTyping: Bool {
        get {
            imChat?.localUserIsTyping ?? false
        }
        set {
            setTyping(newValue)
        }
    }

    public func setTyping(_ typing: Bool) {
        imChat?.localUserIsTyping = typing
    }
}
