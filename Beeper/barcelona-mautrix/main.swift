import Foundation
import Logging
import Sentry
import SwiftCLI

// Set up logging
private let log = Logger(label: "BarcelonaMain")

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

// Set up sentry
func getSerial() -> String? {
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

func configureSentry(dsn: String) {
    SentrySDK.start { options in
        options.dsn = dsn
        if #available(macOS 12.0, *) {
            options.enableMetricKit = true
        }
        options.sendDefaultPii = true
        options.enableAppHangTracking = false
        options.enableAutoSessionTracking = false
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

CFPreferencesSetAppValue("Log" as CFString, false as CFBoolean, kCFPreferencesCurrentApplication)
CFPreferencesSetAppValue("Log.All" as CFString, false as CFBoolean, kCFPreferencesCurrentApplication)

class DaemonCLICommand: Command {
    let name = "daemon"

    @Key("-u", "--unix-socket", description: "Path to the unix socket to use for IPC with mautrix-imessage")
    var unixSocket: String?

    func execute() throws {
        guard let unixSocket else {
            log.error("No --unix-socket specified")
            return
        }

        log.info("DaemonCLICommand")
        BarcelonaMautrix.run(unixSocket)
    }
}

var commands: [Routable] = [
    SendMessageCLICommand(),
    SetMessageRetentionCommand(),
    DaemonCLICommand(),
]

let arguments = ProcessInfo.processInfo.arguments
if arguments.count == 3, arguments[1] == "--unix-socket" {
    // legacy, no command
    log.info("Legacy command fallback")
    BarcelonaMautrix.run(arguments[2])
} else {
    let cli = CLI(name: "barcelona", commands: commands)
    cli.go()
}
