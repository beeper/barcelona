//
//  Scratchbox.swift
//  Barcelona
//
//  Created by Eric Rabil on 1/12/22.
//
//  Traps Barcelona right after initialization and performs arbitrary work
//
//  This file has special attributes so that any changes you make will not be committed.
//

import Foundation

internal let _scratchboxIsEmpty = true

#if DEBUG
import IMCore
import IMSharedUtilities
import IMFoundation
import IDS
import Contacts

internal func _scratchboxMain() {
    
}
#else
internal func _scratchboxMain() {
    
}
#endif
