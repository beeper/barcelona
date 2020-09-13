//
//  Request+IMServiceResource.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

extension Request {
    var service: IMService! {
        get {
            storage[IMServiceStorageKey]
        }
        set {
            storage[IMServiceStorageKey] = newValue
        }
    }
}
