//
//  SetMessageRetentionCommand.swift
//  barcelona-mautrix
//
//  Created by June Welker on 8/1/23.
//

import Foundation
import Logging
import notify
import SwiftCLI

private let log = Logger(label: "SetMessageRetentionCLICommand")

class SetMessageRetentionCommand: Command {
    let name = "set_retention"

    @Param var days: Int

    func execute() throws {
        log.info("Got request to set retention to \(days) day(s)")

        let mobileSMS = "com.apple.MobileSMS" as CFString
        let key = "KeepMessageForDays" as CFString
        // Check if we've already set the value to days
        if (CFPreferencesCopyValue(key, mobileSMS, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? CFIndex) != days {
            log.info("\(key) was not already set, changing to \(days)")
            // If it's not set, just set it for the current user and host
            CFPreferencesSetValue(key, days as CFNumber, mobileSMS, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
            if CFPreferencesSynchronize(mobileSMS, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) {
                // the IMAutomaticHistoryDeletionAgent is only launched when manually invoked or this notification is posted, so this should activate it
                notify_post("com.apple.imautomatichistorydeletionagent.prefchange")

                log.info("Set preferences value and notified deletion agent!")
            } else {
                log.warning("Couldn't synchronize preferences for \(mobileSMS)")
            }
        } else {
            // if we have already set the value correctly, obviously don't do anything
            log.info("\(key) was already set to \(days); not doing anything")
        }
    }
}
