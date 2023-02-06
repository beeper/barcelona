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
import Logging

fileprivate let log = Logger(label: "BLHealthTicker")

public class BLHealthTicker {
    public static let shared = BLHealthTicker()
    
    private var timer: Timer? = nil
    public private(set) lazy var multi = $latestStatus.removeDuplicates().debounce(for: .milliseconds(100), scheduler: DispatchQueue.global(qos: .userInitiated))
    
    public init() {
        NotificationCenter.default.subscribe(toNotificationsNamed: [.IMAccountLoginStatusChanged, .IMAccountRegistrationStatusChanged, .IMAccountNoLongerJustLoggedIn, .IMAccountLoggedIn, .IMAccountLoggedOut, .IMAccountActivated, .IMAccountDeactivated, .IMAccountAuthorizationIDChanged, .IMAccountControllerOperationalAccountsChanged, .IMAccountVettedAliasesChanged, .IMAccountDisplayNameChanged, .IMDaemonDidConnect]) { notification, subscription in
            log.info("Received notification \(notification), updating bridge state to \(self.status.state_event)")
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
    
    public var pinnedBridgeState: BridgeState? {
        didSet {
            var status = BridgeStatusCommand.current
            if let pinnedBridgeState = pinnedBridgeState {
                status.state_event = pinnedBridgeState
            }
            latestStatus = status
        }
    }
    
    @Published
    public private(set) var latestStatus: BridgeStatusCommand = .init(state_event: .unconfigured, ttl: .infinity, has_error: false, info: [:])
    
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
}
