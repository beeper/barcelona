//
//  Request+ChatResource.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

extension Request {
    var imChat: IMChat! {
        get {
            self.storage[IMChatStorageKey]
        }
        set {
            self.storage[IMChatStorageKey] = newValue
        }
    }
    
    var chat: Chat! {
        get {
            imChat?.representation
        }
    }
}
