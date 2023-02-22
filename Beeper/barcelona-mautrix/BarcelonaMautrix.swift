//
//  BarcelonaMautrix.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import BarcelonaMautrixIPC
import Foundation
import IMCore
import Logging
import Sentry
import SwiftCLI

private let log = Logger(label: "BarcelonaMautrix")

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

    static private func configureSentry(dsn: String) {
        SentrySDK.start { options in
            options.dsn = dsn
            if #available(macOS 12.0, *) {
                options.enableMetricKit = true
            }
            options.sendDefaultPii = true
            options.enableAppHangTracking = false
            options.enableAutoSessionTracking = false
            options.profilesSampleRate = 0.1
            options.tracesSampleRate = 0.1
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
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
            return handler
        }

        if let dsn = ProcessInfo.processInfo.environment["BARCELONA_SENTRY_DSN"] {
            log.info("Enabling Sentry")
            configureSentry(dsn: dsn)
        } else if ProcessInfo.processInfo.environment["SENTRY_DSN"] != nil {
            log.warning("Got SENTRY_DSN but expected BARCELONA_SENTRY_DSN, check that the provided DSN is correct")
        } else {
            log.info("Starting without setting up Sentry")
        }

        if let userID = ProcessInfo.processInfo.environment["BARCELONA_SENTRY_USER_ID"] {
            log.info("Setting Sentry user ID to \(userID)")
            let user = User(userId: userID)
            SentrySDK.setUser(user)
        }

        var mautrixIPCChannel: MautrixIPCChannel
        if let unixSocketPath = getUnixSocketPath() {
            let unixMautrixIPCChannel = UnixSocketMautrixIPCChannel(unixSocketPath)
            mautrixIPCChannel = MautrixIPCChannel(
                inputHandle: unixMautrixIPCChannel,
                outputHandle: unixMautrixIPCChannel
            )
        } else {
            mautrixIPCChannel = MautrixIPCChannel(
                inputHandle: FileHandle.standardInput,
                outputHandle: FileHandle.standardOutput
            )
        }

        let barcelonaMautrix = BarcelonaMautrix(mautrixIPCChannel)

        CFPreferencesSetAppValue("Log" as CFString, false as CFBoolean, kCFPreferencesCurrentApplication)
        CFPreferencesSetAppValue("Log.All" as CFString, false as CFBoolean, kCFPreferencesCurrentApplication)

        barcelonaMautrix.run()
    }

    func run() {
        checkArguments()
        bootstrap()

        RunLoop.main.run()
    }

    func bootstrap() {
        log.info("Bootstrapping")

        BarcelonaManager.shared.bootstrap()
            .catch { error in
                log.error("fatal error while setting up barcelona: \(String(describing: error))")
                exit(197)
            }
            .then { success in
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
            LoggingDrivers =
                CBFeatureFlags.runningFromXcode ? [OSLogDriver.shared] : [OSLogDriver.shared, ConsoleDriver.shared]
            BLMetricStore.shared.set(true, forKey: .shouldDebugPayloads)
        }
    }

    // starts the bridge state interval
    func startHealthTicker() {
        BLHealthTicker.shared.subscribeForever { command in
            self.mautrixIPCChannel.writePayload(IPCPayload(command: .bridge_status(command)))
        }

        BLHealthTicker.shared.run(schedulingNext: true)
    }
}
