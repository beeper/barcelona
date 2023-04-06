//
//  IMChatRegistry+SortedRepresentations.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChatRegistry {
    public static var shared: IMChatRegistry {
        IMChatRegistry.sharedInstance()!
    }

    public var allChats: [IMChat] {
        if BLIsSimulation {
            return simulatedChats as! [IMChat]
        } else {
            return allExistingChats ?? []
        }
    }
}
