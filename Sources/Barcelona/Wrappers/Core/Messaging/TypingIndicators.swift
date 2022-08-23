//
//  TypingIndicators.swift
//  Barcelona
//
//  Created by Eric Rabil on 11/2/21.
//

import Foundation

public extension Chat {
    var isTyping: Bool {
        get {
            imChat.localUserIsTyping
        }
        set {
            setTyping(newValue)
        }
    }
    
    func setTyping(_ typing: Bool) {
        imChat.localUserIsTyping = typing
    }
}
