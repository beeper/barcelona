//
//  IPCWrapper.swift
//  BarcelonaIPC
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public class IPCWrapper<PayloadType: RawRepresentable>: NSObject where PayloadType.RawValue == UInt, PayloadType: Codable {
    public typealias Payload = IPCPayload<PayloadType>
    
    public private(set) var port: Port!
    private let mine: Bool
    
    public init(port: Port, mine: Bool) {
        self.port = port
        self.mine = mine
        super.init()
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? IPCWrapper {
            return other.port.isEqual(port)
        }
        
        return false
    }
    
    public override var hash: Int {
        switch port {
        case let port as NSMachPort:
            return Int(port.machPort)
        default:
            return port.hash
        }
    }
    
    deinit {
        deallocate()
    }
    
    internal func deallocate() {
        guard mine else {
            return
        }
        
        switch port {
        case let port as NSMachPort:
            mach_port_deallocate(mach_task_self_, port.machPort)
            self.port = nil
        default:
            break
        }
    }
}
