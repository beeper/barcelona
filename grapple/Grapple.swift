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
        
        let x = Process.self
        
        func run() {
            let exitCode = CLI(name: "grapple", commands: [
                SendMessageCommand(), ChatCommands(), DebugCommands(), ListCommand(), JSCommand()
            ]).go()
            
            guard exitCode == 0 else {
                exit(exitCode)
            }
        }
        
        if let jsIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "js"), ProcessInfo.processInfo.arguments[ProcessInfo.processInfo.arguments.index(after: jsIndex)] == "remote" {
            run()
        } else {
            BarcelonaManager.shared.bootstrap().then { success in
                run()
            }
        }

        RunLoop.main.run()
    }
}
