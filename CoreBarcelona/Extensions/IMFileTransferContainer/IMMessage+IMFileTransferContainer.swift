//
//  IMMessage+IMFileTransferContainer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/4/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension Array: IMFileTransferContainer {
    var fileTransferGUIDs: [String] {
        reduce(into: [String]()) { guids, message in
            guard let container = message as? IMFileTransferContainer else { return }
            guids.append(contentsOf: container.fileTransferGUIDs)
        }
    }
}

extension IMMessage: IMFileTransferContainer {
    var fileTransferGUIDs: [String] {
        value(forKey: "_fileTransferGUIDs") as? [String] ?? []
    }
}

extension IMMessageItem: IMFileTransferContainer {
    var fileTransferGUIDs: [String] {
        value(forKey: "_fileTransferGUIDs") as? [String] ?? []
    }
}
