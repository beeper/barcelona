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

#if DEBUG
import IMCore
import IMSharedUtilities
import IMFoundation
import IDS
#endif

func _scratchboxMain() async {
    let res = try! await IDSResolver.resolveStatus(for: "10293847474388383", on: .iMessage)
}
