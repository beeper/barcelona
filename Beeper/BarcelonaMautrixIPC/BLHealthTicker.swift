//
//  BLHealthTicker.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import Combine

public class BLHealthTicker {
    public static let shared = BLHealthTicker()
    
    private var timer: Timer? = nil
    private var subject: PassthroughSubject<BridgeStatusCommand, Never> = PassthroughSubject()
    public private(set) lazy var multi = subject.share()
    
    public init() {
        NotificationCenter.default.subscribe(toNotificationsNamed: [.IMAccountLoginStatusChanged, .IMAccountRegistrationStatusChanged, .IMAccountNoLongerJustLoggedIn, .IMAccountLoggedIn, .IMAccountLoggedOut, .IMAccountActivated, .IMAccountDeactivated, .IMAccountAuthorizationIDChanged, .IMAccountControllerOperationalAccountsChanged]) { notification, subscription in
            self.run(schedulingNext: true)
        }
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
    
    public var mostRecentStatus: BridgeStatusCommand {
        if let latestStatus = latestStatus {
            return latestStatus
        }
        
        let status = status
        latestStatus = status
        return status
    }
    
    public var pinnedBridgeState: BridgeState? {
        didSet {
            if latestStatus == nil {
                return
            }
            
            var status = BridgeStatusCommand.current
            if let pinnedBridgeState = pinnedBridgeState {
                status.state_event = pinnedBridgeState
            }
            latestStatus = status
        }
    }
    
    private var latestStatus: BridgeStatusCommand? {
        didSet {
            if latestStatus != nil, let pinnedBridgeState = pinnedBridgeState {
                latestStatus!.state_event = pinnedBridgeState
            }
            
            if let latestStatus = latestStatus {
                subject.send(latestStatus)
            }
        }
    }
    
    /**
     Publishes the current bridge status and optionally schedules the next update
     
     - Parameter schedulingNext whether to schedule the next status update
     */
    public func run(schedulingNext shouldScheduleNext: Bool = true) {
        timer?.invalidate()
        latestStatus = .current
        
        if shouldScheduleNext {
            scheduleNext()
        }
    }
    
    private static var cancellables: Set<AnyCancellable> = Set()
    public func subscribeForever(_ callback: @escaping (BridgeStatusCommand) -> ()) {
        let semaphore = DispatchSemaphore(value: 0)
        FileHandle.standardInput.performOnThread {
            self.multi.receive(on: RunLoop.current).sink(receiveValue: callback).store(in: &Self.cancellables)
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    /**
     Terminates the current update loop
     */
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
}
