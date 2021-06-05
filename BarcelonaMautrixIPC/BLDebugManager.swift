//
//  BLDebugDatabase.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/5/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public enum BLDebugPayloadType: String, Codable {
    case request
    case response
}

public class BLDebugManager {
    public static let shared = BLDebugManager()
    fileprivate static let queue = DispatchQueue(label: "BLDebugManager")
    
    public var debugEndpoint = URL(string: "http://localhost:9191/trace")!
    public var shouldDebug = ProcessInfo.processInfo.environment["BLDebugManager"] == "1"
    
    public func trace(request payload: IPCPayload) {
        trace(payload: payload, type: .request)
    }
    
    public func trace(response payload: IPCPayload) {
        trace(payload: payload, type: .response)
    }
    
    public func trace(payload: IPCPayload, type: BLDebugPayloadType) {
        guard shouldDebug else {
            return
        }
        
        inQueue {
            var request = URLRequest(url: self.debugEndpoint)
            request.httpMethod = "PUT"
            
            guard let payloadData = try? JSONEncoder().encode(payload) else {
                return
            }
            
            request.httpBody = payloadData
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            
            let group = DispatchGroup()
            group.enter()
            
            URLSession.shared.dataTask(with: request) { _,_,_  in
                group.leave()
            }
        }
    }
    
    fileprivate func inQueue(_ block: @escaping () -> ()) {
        BLDebugManager.queue.sync {
            block()
        }
    }
}
