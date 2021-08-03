//
//  Date+IMDConversion.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

internal extension Date {
    static func timeIntervalSince1970FromIMDBDateValue(date rawDate: Double) -> Double {
        let rawDateSmall: Double = Double(rawDate / 1000000000)
        
        return Date(timeIntervalSinceReferenceDate: TimeInterval(rawDateSmall)).timeIntervalSince1970 * 1000
    }
}
