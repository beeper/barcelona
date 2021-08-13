//
//  IPCPayload.swift
//  BarcelonaIPC
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public struct IPCPayload<PayloadType: RawRepresentable>: Codable where PayloadType.RawValue == UInt, PayloadType: Codable {
    public let type: PayloadType
    public let payload: Data
    
    public func decode<P: Decodable>() throws -> P {
        try decoder.decode(P.self, from: payload)
    }
}
