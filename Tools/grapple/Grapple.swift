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
import OSLog
import SwiftCLI
import Swog

protocol BarcelonaCommand: Command {}
protocol EphemeralCommand: Command {}
protocol EphemeralBarcelonaCommand: BarcelonaCommand, EphemeralCommand {}

extension Command {
    func connect() -> Promise<Void> {
        BarcelonaManager.shared.bootstrap().then { success in
            guard success else {
                print("Failed to connect to imagent")
                exit(0)
            }
        }
    }
}

@main
class Grapple {
    static let shared = Grapple()
    
    static func main() throws {
        let cli = CLI(name: "grapple", commands: [
            SendMessageCommand(), ChatCommands(), DebugCommands(), ListCommand(), JSCommand(), IDSCommand(), AccountManagement(), Grudge.shared, QueryCommand(), DiagsCommand()
        ])
        LoggingDrivers.append(OSLogDriver.shared)
        
        do {
            let path = try cli.parser.parse(cli: cli, arguments: ArgumentList(arguments: Array(CommandLine.arguments.dropFirst())))
            
            switch path.command {
            case let command as BarcelonaCommand:
                BarcelonaManager.shared.bootstrap().then { success in
                    try command.execute()
                    
                    if command is EphemeralCommand {
                        exit(0)
                    }
                }
            case let command as JSCommand.RemoteREPLCommand:
                try command.execute()
            case let command:
                try command.execute()
                
                if command is EphemeralCommand {
                    exit(0)
                }
            }

            RunLoop.main.run()
        } catch let error as RouteError {
            cli.helpMessageGenerator.writeRouteErrorMessage(for: error, to: Term.stderr)
        } catch let error as OptionError {
            if let command = error.command, command.command is HelpCommand {
                try! command.command.execute()
            }
            
            cli.helpMessageGenerator.writeMisusedOptionsStatement(for: error, to: Term.stderr)
        } catch let error as ParameterError {
            if error.command.command is HelpCommand || cli.helpFlag?.wrappedValue == true {
                try! error.command.command.execute()
            }
            
            cli.helpMessageGenerator.writeParameterErrorMessage(for: error, to: Term.stderr)
        }
    }
}
