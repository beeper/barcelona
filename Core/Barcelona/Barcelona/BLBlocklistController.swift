//
//  BLBlocklistController.swift
//  Barcelona
//
//  Created by Eric Rabil on 4/25/22.
//

import Foundation

public class BLBlocklistController {
    public var testingOverride: Set<String> = Set()
}

extension BLBlocklistController {
    public static let shared = BLBlocklistController()

    public func isSenderBlocked(_ sender: String) -> Bool {
        if testingOverride.contains(sender) {
            return true
        }
        return CMFBlockListIsItemBlocked(CreateCMFItemFromString(sender))
    }
}
