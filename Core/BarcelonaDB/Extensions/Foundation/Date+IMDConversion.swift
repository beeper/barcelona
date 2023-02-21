//
//  Date+IMDConversion.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

private let IMDPersistenceUnixOffset: Int64 = Int64(Date.timeIntervalBetween1970AndReferenceDate * 1_000_000_000)
private let NANOSECONDS_IN_SECOND: Double = 1e9

public func IMDPersistenceTimestampToUnixEpoch(timestamp: Int64) -> Int64 {
    timestamp + IMDPersistenceUnixOffset
}

public func IMDPersistenceTimestampToUnixSeconds(timestamp: Int64) -> Double {
    Double(timestamp + IMDPersistenceUnixOffset) / NANOSECONDS_IN_SECOND
}

extension Date {
    public static func timeIntervalSince1970FromIMDBDateValue(date rawDate: Double) -> Double {
        let rawDateSmall: Double = Double(rawDate / 1_000_000_000)

        return Date(timeIntervalSinceReferenceDate: TimeInterval(rawDateSmall)).timeIntervalSince1970 * 1000
    }

    public var timeIntervalSinceReferenceDateForDatabase: Int {
        Int(timeIntervalSinceReferenceDate * 1_000_000_000)
    }
}
