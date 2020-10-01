//
//  Request+AttachmentResource.swift
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
    var attachment: InternalAttachment! {
        get {
            storage[AttachmentStorageKey]
        }
        set {
            storage[AttachmentStorageKey] = newValue
        }
    }
}
