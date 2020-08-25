//
//  Debouncer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/18/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

class Debouncer {
    var delay: Double
    weak var timer: Timer?

    init(delay: Double) {
        self.delay = delay
    }

    internal func call(_ callback: @escaping () -> ()) {
        timer?.invalidate()
        
        let nextTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            callback()
        }
        
        timer = nextTimer
    }
}
