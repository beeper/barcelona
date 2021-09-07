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
import SwiftyTextTable
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

extension BLContactSuggestionData: TextTableRepresentable {
    public var tableValues: [CustomStringConvertible] {
        [firstName ?? "nil", lastName ?? "nil", image != nil]
    }
    
    public static var columnHeaders: [String] {
        ["firstName", "lastName", "hasAvatar"]
    }
}

class DebugCommands: CommandGroup {
    let name = "debug"
    let shortDescription = "commands useful when debugging barcelona"
    
    class DebugEventsCommand: BarcelonaCommand {
        let name = "events"
        
        func execute() throws {
            let bus = EventBus()

            bus.resume()

            bus.publisher.receiveEvent { event in
                CLInfo("BLEvents", "receiveEvent(%@): %@", event.name.rawValue, String(debugDescribing: event))
            }
        }
    }
    
    class IMDTest: BarcelonaCommand {
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
    
    class NicknameTest: EphemeralBarcelonaCommand {
        let name = "nickname-test"
        
        @Param
        var handleID: String
        
        var normalizedHandleID: String {
            guard handleID.contains(";") else {
                return handleID
            }
            
            return String(handleID.split(separator: ";").last!)
        }
        
        func execute() throws {
            guard let suggestion = BLResolveContactSuggestionData(forHandleID: normalizedHandleID) else {
                print("nil")
                return
            }
            
            print(TextTable(objects: [suggestion]).render())
        }
    }
    
    var children: [Routable] = [DebugEventsCommand(), IMDTest(), NicknameTest()]
}
