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
import OSLog
import IMDPersistence
import SwiftyTextTable
import IMCore
import BarcelonaMautrixIPC

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

private extension Encodable {
    var dump: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            return try String(decoding: encoder.encode(self), as: UTF8.self)
        } catch {
            if let description = (self as? CustomDebugStringConvertible)?.debugDescription {
                return description
            }
            
            return ""
        }
    }
}

class DebugCommands: CommandGroup {
    let name = "debug"
    let shortDescription = "commands useful when debugging barcelona"
    
    
    class DebugEventsCommand: BarcelonaCommand {
        let name = "events"
        
        init() {
//            LoggingDrivers = []
        }
        
        func execute() throws {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            func json<P: Encodable>(_ encodable: P) -> String {
                String(decoding: try! encoder.encode(encodable), as: UTF8.self)
            }
            
            CBDaemonListener.shared.aggregatePipeline.pipe { event in
                CLInfo("BLEvents", "\(json(event))")
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
