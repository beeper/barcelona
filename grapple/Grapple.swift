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
        LoggingDrivers.append(ConsoleDriver.shared)
        
        BarcelonaManager.shared.bootstrap().then { success in
            let exitCode = CLI(name: "grapple", commands: [
                SendMessageCommand(), ChatCommands(), DebugCommands()
            ]).go()
            
            guard exitCode == 0 else {
                exit(exitCode)
            }
        }

        RunLoop.main.run()
    }
}
