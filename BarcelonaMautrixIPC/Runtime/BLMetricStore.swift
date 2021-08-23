//
//  BLMetricStore.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/16/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public class BLMetricStore {
    public static let shared = BLMetricStore()
    
    private init() {}
    
    public enum BLMetricKey: String, Codable {
        case lastSentMessageGUIDs
        case shouldDebugPayloads
    }
    
    public private(set) var metrics = [BLMetricKey: Any]()
    
    public func set<P: Codable>(_ value: P, forKey key: BLMetricKey) {
        metrics[key] = value
    }
    
    public func get(valueForKey key: BLMetricKey) -> Any? {
        metrics[key]
    }
    
    public func get<P: Codable>(typedValue type: P.Type, forKey key: BLMetricKey) -> P? {
        metrics[key] as? P
    }
    
    public func get<P>(key: BLMetricKey) -> P? {
        metrics[key] as? P
    }
}
