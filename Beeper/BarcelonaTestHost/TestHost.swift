//
//  BLTest.swift
//  barcelona
//
//  Created by Eric Rabil on 4/15/22.
//

import XCTHarness

@_cdecl("main") func main() {
    XCTHarnessMain([.mainThreadLiar, .async, .cocoa])
}
