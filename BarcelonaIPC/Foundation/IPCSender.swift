//
//  IPCSender.swift
//  BarcelonaIPC
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public class IPCSender<PayloadType: RawRepresentable>: IPCWrapper<PayloadType> where PayloadType.RawValue == UInt, PayloadType: Codable {
    public typealias Receiver = IPCReceiver<PayloadType>
    public typealias Callback = (Payload, IPCSender?) -> ()
    
    public static func serverSender(named name: String) -> IPCSender? {
        var send_port: mach_port_name_t = 0
        
        guard bootstrap_look_up(bootstrap_port, name, &send_port) == KERN_SUCCESS else {
            return nil
        }
        
        return IPCSender(port: NSMachPort(machPort: send_port), mine: true)
    }
    
    internal func send(payload: Payload, fromPort from: Port?) {
        port.send(before: Date(timeIntervalSinceNow: 0), components: [try! encoder.encode(payload)], from: from, reserved: 0)
    }
    
    public func send(payload: Payload) {
        send(payload: payload, fromPort: nil)
    }
    
    public func send(payload: Payload, withReceiver receiver: Receiver) {
        send(payload: payload, fromPort: receiver.port)
    }
}

public extension IPCSender {
    func send(payload: Payload, handlingReply block: @escaping Callback) {
        var anon: Receiver!
        
        anon = Receiver.anonymousReceiver { payload, replyPort, receiver in
            anon = nil
            
            block(payload, replyPort)
        }
        
        send(payload: payload, withReceiver: anon)
    }
}

public extension IPCSender {
    func send<Content: Codable>(content: Content, type: PayloadType) {
        send(payload: Payload(type: type, payload: try! encoder.encode(content)))
    }
    
    func send<Content: Codable>(content: Content, type: PayloadType, withReceiver receiver: Receiver) {
        send(payload: Payload(type: type, payload: try! encoder.encode(content)), withReceiver: receiver)
    }
    
    func send<Content: Codable>(content: Content, type: PayloadType, handlingReply block: @escaping Callback) {
        send(payload: Payload(type: type, payload: try! encoder.encode(content)), handlingReply: block)
    }
}

public extension IPCSender {
    func send<Content: Codable>(contentBlockingUntilReply content: Content, type: PayloadType) -> (Payload, IPCSender?) {
        var retval: (Payload, IPCSender?)?
        let sema = DispatchSemaphore(value: 0)
        
        send(content: content, type: type) { payload, sender in
            retval = (payload, sender)
            sema.signal()
        }
        
        sema.wait()
        
        return retval!
    }
}
