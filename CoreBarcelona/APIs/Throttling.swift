//
//  Throttling.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Combine
import Vapor
import NIO

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

/**
 Tracks API consumption for a given IP
 */
private class AllotmentTracker: Debouncer {
    var allotments: Int = 0
    private let maximum: Int
    
    var remaining: Int {
        maximum - allotments
    }
    
    init(delay: Double, maximum: Int) {
        self.maximum = maximum
        super.init(delay: delay)
    }
    
    func consume() -> Bool {
        if (allotments + 1) > maximum {
            return false
        }
        
        self.allotments += 1
        
        DispatchQueue.main.async {
            super.call {
                DispatchQueue.main.async {
                    print("Allotments released.")
                    self.allotments = 0
                }
            }
        }
        
        return true
    }
}

/**
 Throttles a given request or request group to the given allotment within a given window
 */
class ThrottlingMiddleware: Middleware {
    /** Number of requests that can be made in a given interval */
    var allotment: Int
    /** Time, in seconds, before allotment consumption expires */
    var expiration: Int
    
    init(allotment: Int, expiration: Int) {
        self.allotment = allotment
        self.expiration = expiration
    }
    
    /**
     Current allotments to a given socket address
     */
    private var consumers: [String: AllotmentTracker] = [String: AllotmentTracker]()
    
    private func consumer(for ipAddress: String) -> AllotmentTracker {
        guard let consumer = consumers[ipAddress] else {
            consumers[ipAddress] = AllotmentTracker(delay: Double(expiration), maximum: allotment)
            return consumers[ipAddress]!
        }
        
        return consumer
    }
    
    /**
     Attempt to grant allotment to a socket address
     */
    private func access(address: SocketAddress?) -> Bool {
        guard let ipAddress = address?.ipAddress else {
            return false
        }
        
        let consumer = self.consumer(for: ipAddress)
        
        return consumer.consume()
    }
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        /** Handle rejected allotment */
        if access(address: request.remoteAddress) == false {
            var res = Abort(.tooManyRequests)
            res.headers.add(name: "Retry-After", value: String(self.expiration))
            
            return request.eventLoop.makeFailedFuture(res)
        }
        
        /** Send ratelimit metadata headers */
        if let ipAddress = request.remoteAddress?.ipAddress {
            let consumer = self.consumer(for: ipAddress)
            
            return next.respond(to: request).map { res in
                res.headers.add(name: "RateLimit-Limit", value: String(self.allotment))
                res.headers.add(name: "RateLimit-Remaining", value: String(consumer.remaining))
                
                return res
            }
        }
        
        return next.respond(to: request)
    }
}
