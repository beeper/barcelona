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
        case shouldDebugPayloads
    }

    public private(set) var metrics = [BLMetricKey: Any]()

    public func set<P: Codable>(_ value: P, forKey key: BLMetricKey) {
        metrics[key] = value
    }

    public func get<P>(key: BLMetricKey) -> P? {
        metrics[key] as? P
    }
}
