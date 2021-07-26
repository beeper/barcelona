//
//  DebugCommands.swift
//  grapple
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import SwiftCLI
import BarcelonaEvents
import OSLog

private extension String {
    init(debugDescribing value: Any) {
        if let debugConvertable = value as? CustomDebugStringConvertible {
            self.init(debugConvertable.debugDescription)
        } else {
            self.init(describing: value)
        }
    }
}

class DebugCommands: CommandGroup {
    let name = "debug"
    let shortDescription = "commands useful when debugging barcelona"
    
    class DebugEventsCommand: Command {
        let name = "events"
        
        func execute() throws {
            let bus = EventBus()

            let log = OSLog(subsystem: "com.ericrabil.grapple", category: "EventBusLogging")
            log.rerouteToStandardOutput = true
            
            bus.resume()

            bus.publisher.receiveEvent { event in
                log("receiveEvent(%@): %@", event.label, String(debugDescribing: event.value))
            }
        }
    }
    
    var children: [Routable] = [DebugEventsCommand()]
}
