//
//  IPCReceiver.swift
//  BarcelonaIPC
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

@_silgen_name("bootstrap_check_in")
func bootstrap_check_in(_ bootstrap_port: mach_port_t, _ service_name: UnsafePointer<CChar>, _ port: UnsafeMutablePointer<mach_port_t>) -> kern_return_t

public class IPCReceiver<PayloadType: RawRepresentable>: IPCWrapper<PayloadType>, PortDelegate where PayloadType.RawValue == UInt, PayloadType: Codable {
    public typealias ReceiverCallback = (Payload, IPCSender<PayloadType>?, IPCReceiver) -> ()
    
    public static func anonymousReceiver(_ responseHandler: @escaping ReceiverCallback) -> IPCReceiver {
        IPCReceiver(port: IPCReceivePort(), mine: true, handleResponse: responseHandler)
    }
    
    public static func serverReceiver(named name: String, _ responseHandler: @escaping ReceiverCallback) -> IPCReceiver {
        var existingPort: mach_port_t = 0
        
        if bootstrap_check_in(bootstrap_port, name, &existingPort) == KERN_SUCCESS, existingPort != 0 {
            return IPCReceiver(port: IPCWrapPort(existingPort), mine: true, handleResponse: responseHandler)
        }
        
        let port = IPCReceivePort()
        
        guard bootstrap_register(bootstrap_port, "com.barcelona.js-server", port.machPort) == KERN_SUCCESS else {
            fatalError("failed to register with bootstrap")
        }
        
        return IPCReceiver(port: port, mine: true, handleResponse: responseHandler)
    }
    
    public let handleResponse: ReceiverCallback
    
    public init(port: Port, mine: Bool, handleResponse: @escaping ReceiverCallback) {
        self.handleResponse = handleResponse
        super.init(port: port, mine: mine)
        
        port.setDelegate(self)
    }

    public func handle(_ message: PortMessage) {
        guard let payloadData = message.components?.first as? Data, let payload = try? decoder.decode(Payload.self, from: payloadData) else {
            return
        }
        
        if let sendPort = message.sendPort {
            handleResponse(payload, IPCSender(port: sendPort, mine: false), self)
        } else {
            handleResponse(payload, nil, self)
        }
    }
}
