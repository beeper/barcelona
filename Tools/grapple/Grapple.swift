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
import FeatureFlags
@_spi(featureFlags) @_spi(scratchbox) import Barcelona

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

#if DEBUG
let isDebugBuild = true
#else
let isDebugBuild = false
#endif

class GrappleFlags: FlagProvider {
    let suiteName = "com.ericrabil.grapple"
    
    @FeatureFlag("logging", defaultValue: isDebugBuild)
    var enableLogging: Bool
    
    static let shared = GrappleFlags()
}

class ScratchboxCommand: Command {
    let name = "scratchbox"
    
    func execute() throws {
        guard BLSetup() else {
            fatalError()
        }
        _scratchboxMain()
        RunLoop.current.run()
    }
}

@main
class Grapple {
    static let shared = Grapple()
    
    static func main() throws {
        
        CBFeatureFlags.overrideWithholdPartialFailures = false
        CBFeatureFlags.overrideWithholdDupes = false
        let cli = CLI(name: "grapple", commands: [
            SendMessageCommand(), ChatCommands(), DebugCommands(), ListCommand(), JSCommand(), IDSCommand(), AccountManagement(), Grudge.shared, QueryCommand(), DiagsCommand(), MessageCommand(), ScratchboxCommand()
        ])
        LoggingDrivers.append(OSLogDriver.shared)
        if !GrappleFlags.shared.enableLogging {
            LoggingDrivers.removeAll(where: { $0 === ConsoleDriver.shared })
        }
        
        cli.globalOptions.append(contentsOf: GrappleFlags.shared.allFlags.map(\.key).flatMap { key in ["--enable-\(key)", "--disable-\(key)"] }.map { Flag($0) })
        
        #if !DEBUG
        if !ProcessInfo.processInfo.environment.keys.contains("I_HAVE_CONSENT") {
            print("STOP! Do you have permission from the user to access these APIs? [y/N]")
            guard readLine(strippingNewline: true)?.lowercased() == "y" else {
                exit(1)
            }
        }
        #endif
        
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
