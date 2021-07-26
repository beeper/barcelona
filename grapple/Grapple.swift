//
//  main.swift
//  grapple
//
//  Created by Eric Rabil on 7/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import JavaScriptCore
import Barcelona
import BarcelonaEvents
import OSLog
import SwiftCLI



@main
class Grapple {
    static let shared = Grapple()
    
    static func main() {
        BarcelonaManager.shared.bootstrap().whenSuccess { success in
            CLI(name: "grapple", commands: [
                SendMessageCommand(), ChatCommands(), DebugCommands()
            ]).go()
        }

        RunLoop.main.run()
    }
}
