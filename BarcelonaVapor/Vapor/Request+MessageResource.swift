//
//  Request+MessageResource.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import IMCore
import Vapor

extension Request {
    var imMessage: IMMessage! {
        get {
            self.storage[IMMessageStorageKey]
        }
        set {
            self.storage[IMMessageStorageKey] = newValue
        }
    }
    
    var message: Message! {
        get {
            self.storage[MessageStorageKey]
        }
        set {
            self.storage[MessageStorageKey] = newValue
        }
    }
}
