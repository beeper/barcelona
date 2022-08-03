//
//  RegressionTesting.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/3/22.
//

import Foundation
import Swog
import Barcelona

public struct RegressionTesting {
    public static let tests = [
        "BRI4498": BRI4498
    ]
}

public extension RegressionTesting {
    static func BRI4498() {
        let log = Logger(category: "RGT-BRI4498", subsystem: "com.beeper.imc.regression-testing")
        let tracer = Tracer(log, true)
        
        BMXContactListDebug = true
        CBSenderCorrelationController.debug = true
        defer { BMXContactListDebug = false }
        defer { CBSenderCorrelationController.debug = false }
        
        
        func go(prewarm: Bool) {
            log.info("Testing with prewarm=\(prewarm, privacy: .public)")
            CBSenderCorrelationController.shared.reset()
            if prewarm {
                BMXPrewarm()
            }
            let (contacts, time) = tracer.time(callback: { BMXGenerateContactList(omitAvatars: true, asyncLookup: false) })
            log.info("Loaded \(contacts.count, privacy: .public) contacts in \(time, privacy: .public)s")
        }
        
        go(prewarm: true)
        go(prewarm: false)
    }
}
