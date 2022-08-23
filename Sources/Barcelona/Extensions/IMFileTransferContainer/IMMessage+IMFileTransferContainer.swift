//
//  IMMessage+IMFileTransferContainer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities

extension Array: IMFileTransferContainer where Element: IMFileTransferContainer {
    @usableFromInline
    var fileTransferGUIDs: [String] {
        flatMap(\.fileTransferGUIDs)
    }
}

extension IMMessage: IMFileTransferContainer {
    @usableFromInline
    var fileTransferGUIDs: [String] {
        get {
            __fileTransferGUIDs ?? []
        }
        set {
            __fileTransferGUIDs = newValue
        }
    }
}

extension IMMessageItem: IMFileTransferContainer {
}
