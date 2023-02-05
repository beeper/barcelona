//
//  BarcelonaMautrix.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import BarcelonaMautrixIPC
import IMCore
import SwiftCLI
import Sentry

private let log = Logger(category: "ERBarcelonaManager", subsystem: "com.beeper.imc.barcelona-mautrix")

@main
class BarcelonaMautrix {
    private let mautrixIPCChannel: MautrixIPCChannel
    private let reader: BLPayloadReader
    private let eventHandler: BLEventHandler
    
    init(_ mautrixIPCChannel: MautrixIPCChannel) {
        self.mautrixIPCChannel = mautrixIPCChannel
        reader = BLPayloadReader(ipcChannel: mautrixIPCChannel)
        eventHandler = BLEventHandler(ipcChannel: mautrixIPCChannel)
    }
    
    static func configureSentry() {
        if let configurator = IMCSharedSentryConfigurator() {
            CLInfo("CoreSentry", "Setting up CoreSentry-flavored Sentry integration")
            configurator.productName = "barcelona-mautrix"
            // even if CoreSentry is a release build we might be a debug build
            configurator.debug = ProcessInfo.processInfo.environment.keys.contains("DEBUG_SENTRY")
            if !configurator.knownProduct {
                CLWarn("CoreSentry", "CoreSentry has no DSN for us!")
            }
            configurator.startSentry()
            if ProcessInfo.processInfo.arguments.count > 1, ProcessInfo.processInfo.arguments[1] == "sentry" {
                let cli = CLI(name: "barcelona-mautrix")
                cli.commands = [SentryCLICommandGroup(configurator.commandGroup)]
                cli.goAndExit()
            }
        } else if let dsn = ProcessInfo.processInfo.environment["SENTRY_DSN"] {
            CLInfo("CoreSentry", "Setting up fallback sentry using DSN \(dsn)")
            SentrySDK.start { options in
                options.dsn = dsn
            }
        } else {
            CLInfo("CoreSentry", "Starting without setting up Sentry")
        }
    }
    
    static func getUnixSocketPath() -> String? {
        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: "--unix-socket"),
            ProcessInfo.processInfo.arguments.count > index + 1
        else {
            return nil
        }
        return ProcessInfo.processInfo.arguments[index + 1]
    }
    
    static func main() {
        var mautrixIPCChannel: MautrixIPCChannel
        if let unixSocketPath = getUnixSocketPath() {
            let unixMautrixIPCChannel = UnixSocketMautrixIPCChannel(unixSocketPath)
            mautrixIPCChannel = MautrixIPCChannel(inputHandle: unixMautrixIPCChannel, outputHandle: unixMautrixIPCChannel)
            
            LoggingDrivers = [OSLogDriver.shared, ConsoleDriver.shared]
        } else {
            mautrixIPCChannel = MautrixIPCChannel(inputHandle: FileHandle.standardInput, outputHandle: FileHandle.standardOutput)
            
            LoggingDrivers = [BLMautrixSTDOutDriver(ipcChannel: mautrixIPCChannel), OSLogDriver.shared]
        }
        
        let barcelonaMautrix = BarcelonaMautrix(mautrixIPCChannel)
        
        CFPreferencesSetAppValue("Log" as CFString, false as CFBoolean, kCFPreferencesCurrentApplication)
        CFPreferencesSetAppValue("Log.All" as CFString, false as CFBoolean, kCFPreferencesCurrentApplication)
        
        configureSentry()
        
        barcelonaMautrix.run()
    }
    
    func run() {
        checkArguments()
        bootstrap()
        
        RunLoop.main.run()
    }
    
    func bootstrap() {
        log.info("Bootstrapping")
        
        BarcelonaManager.shared.bootstrap().catch { error in
            log.fault("fatal error while setting up barcelona: \(String(describing: error))")
            exit(197)
        }.then { success in
            guard success else {
                log.error("Failed to bootstrap")
                exit(-1)
            }
            
            // allow payloads to start flowing
            self.reader.ready = true
            BLHealthTicker.shared.pinnedBridgeState = nil
            
            CBPurgedAttachmentController.shared.enabled = true
            CBPurgedAttachmentController.shared.delegate = self.eventHandler
            
            // starts the imessage notification processor
            self.eventHandler.run()
            
            log.info("BLMautrix is ready")
            
            self.startHealthTicker()
        }
    }
    
    func checkArguments() {
        // apply debug overlays for easier log reading
        if ProcessInfo.processInfo.arguments.contains("-d") {
            LoggingDrivers = CBFeatureFlags.runningFromXcode ? [OSLogDriver.shared] : [OSLogDriver.shared, ConsoleDriver.shared]
            BLMetricStore.shared.set(true, forKey: .shouldDebugPayloads)
        }

        // Only correlate chats if mautrix wants us to merge them
        CBFeatureFlags.correlateChats = MXFeatureFlags.shared.mergedChats
        log.info("mergedChats flag: \(MXFeatureFlags.shared.mergedChats)")
    }
    
    // starts the bridge state interval
    func startHealthTicker() {
        BLHealthTicker.shared.subscribeForever { command in
            self.mautrixIPCChannel.writePayload(IPCPayload(command: .bridge_status(command)))
        }
        
        BLHealthTicker.shared.run(schedulingNext: true)
    }
}
