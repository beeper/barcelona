//
//  BLBlocklistController.swift
//  Barcelona
//
//  Created by Eric Rabil on 4/25/22.
//

import Foundation

public class BLBlocklistController {
    @_spi(unitTestInternals) public var testingOverride: Set<String> = Set()
}

public extension BLBlocklistController {
    static let shared = BLBlocklistController()
    
    func isSenderBlocked(_ sender: String) -> Bool {
        guard CBFeatureFlags.enableBlocklist else {
            return false
        }
        if testingOverride.contains(sender) {
            return true
        }
        return CMFBlockListIsItemBlocked(CreateCMFItemFromString(sender))
    }
}
