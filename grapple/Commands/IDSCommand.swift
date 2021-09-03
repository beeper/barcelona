////  IDSCommand.swift
//  grapple
//
//  Created by Eric Rabil on 9/3/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftCLI
import Barcelona
import SwiftyTextTable

extension IDSState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .available:
            return "available"
        case .unavailable:
            return "unavailable"
        case .unknown:
            return "unknown"
        }
    }
}

struct IDSResult: TextTableRepresentable {
    let id: String
    let state: IDSState
    
    var tableValues: [CustomStringConvertible] {
        [id, state.debugDescription]
    }
    
    static var columnHeaders: [String] {
        ["id", "state"]
    }
}

public class IDSCommand: EphemeralCommand {
    public let name = "ids"
    
    @Param
    var service: String
    
    @CollectedParam
    var handles: [String]
    
    public func execute() throws {
        guard let service = IMServiceStyle(rawValue: service) else {
            fatalError("Invalid service name")
        }
        
        print(try BLResolveIDStatusForIDs(handles, onService: service).map(IDSResult.init(id:state:)).renderTextTable())
    }
}
