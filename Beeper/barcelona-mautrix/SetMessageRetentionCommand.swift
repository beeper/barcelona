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
        let mobileSMS = "com.apple.MobileSMS" as CFString
        let key = "KeepMessageForDays" as CFString
        var currentVal: DarwinBoolean = false
        withUnsafeMutablePointer(to: &currentVal) { hasVal in
            // Check if we've already set the value to 1
            let val = CFPreferencesGetAppIntegerValue(key, mobileSMS, hasVal)

            // if we have already set the value correctly, obviously don't do anything
            if hasVal.pointee != true || val != days {
                log.info("\(key) was not already set, changing to \(days)")
                // If it's not set, just set it for the current user and host
                CFPreferencesSetValue(key, days as CFNumber, mobileSMS, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
                CFPreferencesAppSynchronize(mobileSMS)
                // the IMAutomaticHistoryDeletionAgent is only launched when manually invoked or this notification is posted, so this should activate it
                notify_post("com.apple.imautomatichistorydeletionagent.prefchange")

                log.info("Set preferences value and notified deletion agent!")
            } else {
                log.info("\(key) was already set to \(days); not doing anything")
            }
        }
    }
}
