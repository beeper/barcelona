//
//  BLHealthTicker.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

public class BLHealthTicker {
    public static let shared = BLHealthTicker()
    
    private var timer: Timer? = nil
    
    private var publish: (BridgeStatusCommand) -> () = { _ in }
    public let stream: SubjectStream<BridgeStatusCommand>
    
    public init() {
        stream = SubjectStream<BridgeStatusCommand>(publish: &publish)
    }
    
    /// The current bridge status
    public var status: BridgeStatusCommand {
        .current
    }
    
    /**
     Schedules a delayed bridge status update
     */
    public func scheduleNext() {
        timer = Timer.scheduledTimer(withTimeInterval: status.ttl, repeats: false) { timer in
            self.run(schedulingNext: true)
        }
    }
    
    /**
     Publishes the current bridge status and optionally schedules the next update
     
     - Parameter schedulingNext whether to schedule the next status update
     */
    public func run(schedulingNext scheduleNext: Bool = true) {
        self.publish(self.status)
        
        if scheduleNext {
            self.scheduleNext()
        }
    }
    
    /**
     Terminates the current update loop
     */
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
}
