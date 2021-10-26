//
//  IMMessage+IMFileTransferContainer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension Array: IMFileTransferContainer where Element: IMFileTransferContainer {
    @usableFromInline
    var fileTransferGUIDs: [String] {
        flatMap(\.fileTransferGUIDs)
    }
}

extension IMMessage: IMFileTransferContainer {
    @usableFromInline
    var fileTransferGUIDs: [String] {
        value(forKey: "_fileTransferGUIDs") as? [String] ?? []
    }
}

extension IMMessageItem: IMFileTransferContainer {
    @usableFromInline
    var fileTransferGUIDs: [String] {
        value(forKey: "_fileTransferGUIDs") as? [String] ?? []
    }
}
