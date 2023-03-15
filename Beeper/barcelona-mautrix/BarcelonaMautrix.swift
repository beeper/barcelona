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

private let log = Logger(label: "BarcelonaMautrix")

@main
class BarcelonaMautrix {
    private let mautrixIPCChannel: MautrixIPCChannel
    private let reader: BLPayloadReader
    private let eventHandler: BLEventHandler
    private let chatRegistry: CBChatRegistry

    init(_ mautrixIPCChannel: MautrixIPCChannel) {
        self.mautrixIPCChannel = mautrixIPCChannel
        let chatRegistry = CBChatRegistry()
        reader = BLPayloadReader(ipcChannel: mautrixIPCChannel, chatRegistry: chatRegistry)
        eventHandler = BLEventHandler(ipcChannel: mautrixIPCChannel)
        self.chatRegistry = chatRegistry
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
            options.profilesSampleRate = 1
            options.tracesSampleRate = 0.1
            options.maxBreadcrumbs = 200
            if let info = Bundle.main.infoDictionary,
                let bundleIdentifier = info["CFBundleIdentifier"],
                let bundleVersion = info["CFBundleVersion"] as? String
            {
                options.releaseName = "\(bundleIdentifier)@\(bundleVersion)"
            }

            if let serial = getSerial() {
                SentrySDK.configureScope { scope in
                    scope.setTag(value: "device.serial", key: serial)
                }
            }
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
        SentrySDK.startTransaction(name: "BarcelonaMautrix", operation: "startup", bindToScope: true)
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
            return MultiplexLogHandler(
                [
                    handler,
                    SentryLogHandler(label: label),
                    OSLogHandler(label: label),
                ]
            )
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
        bootstrap()

        RunLoop.main.run()
    }

    func bootstrap() {
        let startupSpan = SentrySDK.span
        let bootstrapSpan = startupSpan?.startChild(operation: "bootstrap")
        log.info("Bootstrapping")

        BarcelonaManager.shared.bootstrap(chatRegistry: chatRegistry)
            .catch { error in
                log.error("fatal error while setting up barcelona: \(String(describing: error))")
                startupSpan?.finish(status: .internalError)
                bootstrapSpan?.finish(status: .internalError)
                exit(197)
            }
            .then { success in
                guard success else {
                    log.error("Failed to bootstrap")
                    startupSpan?.finish(status: .internalError)
                    bootstrapSpan?.finish(status: .internalError)
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
                bootstrapSpan?.finish()
                startupSpan?.finish()
            }
    }

    // starts the bridge state interval
    func startHealthTicker() {
        BLHealthTicker.shared.subscribeForever { command in
            self.mautrixIPCChannel.writePayload(IPCPayload(command: .bridge_status(command)))
        }

        BLHealthTicker.shared.run(schedulingNext: true)
    }

    private static func getSerial() -> String? {
        let platformExpert = IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        defer {
            IOObjectRelease(platformExpert)
        }

        guard platformExpert > 0 else {
            return nil
        }

        guard
            let serialNumber =
                (IORegistryEntryCreateCFProperty(
                    platformExpert,
                    kIOPlatformSerialNumberKey as CFString,
                    kCFAllocatorDefault,
                    0
                )
                .takeUnretainedValue() as? String)?
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        else {
            return nil
        }

        return serialNumber
    }
}
