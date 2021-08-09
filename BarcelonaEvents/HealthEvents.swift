//
//  HealthEvents.swift
//  BarcelonaEvents
//
//  Created by Eric Rabil on 8/9/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona

private extension HealthChecker {
    /// A snapshot of the health at a given moment in time
    var state: HealthState {
        HealthState(authenticationState: authenticationState, connectionState: connectionState)
    }
}

class HealthEvents: EventDispatcher {
    private var subscription: NotificationSubscription?
    
    override func sleep() {
        subscription = nil
    }
    
    override func wake() {
        subscription = HealthChecker.shared.observeHealth { health in
            self.bus.dispatch(.healthChanged(health.state))
        }
    }
}
