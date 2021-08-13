//
//  IPCController.swift
//  BarcelonaIPC
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

@_silgen_name("bootstrap_register")
func bootstrap_register(_ bootstrap: mach_port_t, _ name: UnsafePointer<CChar>, _ port: mach_port_t) -> kern_return_t

@_silgen_name("bootstrap_look_up")
func bootstrap_look_up(_ bootstrap: mach_port_t, _ name: UnsafePointer<CChar>, _ port: UnsafeMutablePointer<mach_port_t>) -> kern_return_t

internal let decoder = JSONDecoder()
internal let encoder = JSONEncoder()

internal func IPCWrapPort(_ port: mach_port_t) -> NSMachPort {
    let port = NSMachPort(machPort: port)
    RunLoop.main.add(port, forMode: .default)
    
    return port
}

internal func IPCReceivePort() -> NSMachPort {
    var rcv_port: mach_port_name_t = 0
    
    guard mach_port_allocate(mach_task_self_, MACH_PORT_RIGHT_RECEIVE, &rcv_port) == KERN_SUCCESS else {
        fatalError("Failed to setup receive port")
    }
    
    guard mach_port_insert_right(mach_task_self_, rcv_port, rcv_port, .init(MACH_MSG_TYPE_MAKE_SEND)) == KERN_SUCCESS else {
        fatalError("failed to add send right")
    }
    
    return IPCWrapPort(rcv_port)
}
