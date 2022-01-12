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
import BarcelonaJS

@main
class BarcelonaMautrix {
    static let shared = BarcelonaMautrix()
    
    let reader = BLPayloadReader()
    
    static func main() {
        LoggingDrivers = [BLMautrixSTDOutDriver.shared, OSLogDriver.shared]
        
        CFPreferencesSetAppValue("Log" as CFString, false as CFBoolean, kCFPreferencesCurrentApplication)
        CFPreferencesSetAppValue("Log.All" as CFString, false as CFBoolean, kCFPreferencesCurrentApplication)
        
        shared.run()
    }
    
    func run() {
        checkArguments()
        bootstrap()
        if BLRuntimeConfiguration.jsIPC {
            startJSContext()
        }
        
        RunLoop.main.run()
    }
    
    func bootstrap() {
        reader.stream.subscribe { payload in
            // pipe payload to central logic
            BLHandlePayload(payload)
        }

        CLInfo("ERBarcelonaManager", "Bootstrapping")

        BarcelonaManager.shared.bootstrap().then { success in
            guard success else {
                CLError("ERBarcelonaManager", "Failed to bootstrap")
                exit(-1)
            }
            
            // allow payloads to start flowing
            self.reader.ready = true
            
            CBPurgedAttachmentController.shared.enabled = true
            CBPurgedAttachmentController.shared.delegate = BLEventHandler.shared
            
            CLInfo("ERBarcelonaManager", "BLMautrix is ready")
            
            // starts the imessage notification processor
            BLEventHandler.shared.run()
            
            CLInfo("ERBarcelonaManager", "BLMautrix event handler is running")
            
            self.startHealthTicker()
        }
    }
    
    func checkArguments() {
        // apply debug overlays for easier log reading
        if ProcessInfo.processInfo.arguments.contains("-d") {
            LoggingDrivers = CBFeatureFlags.runningFromXcode ? [OSLogDriver.shared] : [OSLogDriver.shared, ConsoleDriver.shared]
            BLMetricStore.shared.set(true, forKey: .shouldDebugPayloads)
        }
    }
    
    // starts the bridge state interval
    func startHealthTicker() {
        BLHealthTicker.shared.stream.subscribe { command in
            BLWritePayload(IPCPayload(command: .bridge_status(command)))
        }
        
        BLHealthTicker.shared.run(schedulingNext: true)
    }
    
    // starts a js ipc server for hot debugging
    func startJSContext() {
        Thread {
            let thread = JBLCreateJSContext()
            let server = BarcelonaJSIPCServer(context: thread)
            
            RunLoop.current.run()
        }.start()
    }
}
