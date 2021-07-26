//
//  IMItem|IMMessage+TimeResolvers.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct TimeReceipt {
    public var time: Double = 0
    public var timeDelivered: Double = 0
    public var timeRead: Double = 0
    public var timePlayed: Double = 0
    
    public var asTuple: (Double, Double, Double, Double) {
        (time, timeDelivered, timeRead, timePlayed)
    }
    
    public mutating func merge(receipt: TimeReceipt) {
        if time == 0 {
            time = receipt.time
        }
        
        if timeDelivered == 0 {
            timeDelivered = receipt.timeDelivered
        }
        
        if timeRead == 0 {
            timeRead = receipt.timeRead
        }
        
        if timePlayed == 0 {
            timePlayed = receipt.timePlayed
        }
    }
    
    public func merging(receipt: TimeReceipt) -> TimeReceipt {
        var receipt = self
        receipt.merge(receipt: receipt)
        
        return receipt
    }
    
    public func assign(toMessage message: inout Message) {
        message.time = time
        message.timeDelivered = timeDelivered
        message.timeRead = timeRead
        message.timePlayed = timePlayed
    }
}

extension Optional where Wrapped == Date {
    var normalized: Double {
        self?.timeIntervalSince1970 ?? 0
    }
}

protocol TimeReceiptFactory {
    var receipt: TimeReceipt { get }
}

extension IMItem {
    var bareReceipt: TimeReceipt {
        TimeReceipt(
            time: time.normalized,
            timeDelivered: 0,
            timeRead: 0,
            timePlayed: 0
        )
    }
}

extension IMMessageItem: TimeReceiptFactory {
    var receipt: TimeReceipt {
        TimeReceipt(
            time: time.normalized,
            timeDelivered: timeDelivered.normalized,
            timeRead: timeRead.normalized,
            timePlayed: timePlayed.normalized
        )
    }
}

extension IMMessage: TimeReceiptFactory {
    var receipt: TimeReceipt {
        TimeReceipt(
            time: time.normalized,
            timeDelivered: timeDelivered.normalized,
            timeRead: timeRead.normalized,
            timePlayed: timePlayed.normalized
        )
    }
}
