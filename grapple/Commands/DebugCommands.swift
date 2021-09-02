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
import IMDPersistence
import IMCore

private extension String {
    init(debugDescribing value: Any) {
        if let debugConvertable = value as? CustomDebugStringConvertible {
            self.init(debugConvertable.debugDescription)
        } else {
            self.init(describing: value)
        }
    }
}

@_cdecl("_CSDBCheckResultWithStatement")
func _CSDBCheckResultWithStatement(_ a: UnsafeRawPointer, _ b: UnsafeRawPointer, _ c: UnsafeRawPointer, _ d: UnsafeRawPointer, _ e: UnsafeRawPointer) {
    
}

class DebugCommands: CommandGroup {
    let name = "debug"
    let shortDescription = "commands useful when debugging barcelona"
    
    class DebugEventsCommand: Command {
        let name = "events"
        
        func execute() throws {
            let bus = EventBus()

            bus.resume()

            bus.publisher.receiveEvent { event in
                CLInfo("BLEvents", "receiveEvent(%@): %@", event.name.rawValue, String(debugDescribing: event))
            }
        }
    }
    
    class IMDTest: Command {
        let name = "imd"
        
        func execute() throws {
            
            guard let _chat = IMChatRegistry.shared.allChats.first else {
                return
            }
            
            typealias XYZ = @convention(c) (UnsafeRawPointer, UnsafeRawPointer, UnsafeRawPointer, UnsafeRawPointer, UnsafeRawPointer) -> ()
            
            let chat = Chat(_chat)
            
            chat.messages().then {
                print($0)
            }
        }
    }
    
    var children: [Routable] = [DebugEventsCommand(), IMDTest()]
}
