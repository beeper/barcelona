//
//  DigitalTouchMessage+Codable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

extension DigitalTouchMessage: Codable {
    private enum DigitalTouchType: String, Codable, CodingKey {
        case sketch
        case video
        case tap
        case heartbeat
        case anger
        case kiss
    }
    
    private var type: DigitalTouchType {
        switch self {
        case .anger(_):
            return .anger
        case .heartbeat(_):
            return .heartbeat
        case .kiss(_):
            return .kiss
        case .sketch(_):
            return .sketch
        case .tap(_):
            return .tap
        case .video(_):
            return .video
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let itemType = try container.decode(DigitalTouchType.self, forKey: .type)
        
        switch itemType {
        case .anger:
            self = .anger(try container.decode(ETAngerData.self, forKey: .payload))
        case .heartbeat:
            self = .heartbeat(try container.decode(ETHeartbeatData.self, forKey: .payload))
        case .kiss:
            self = .kiss(try container.decode(ETKissData.self, forKey: .payload))
        case .sketch:
            self = .sketch(try container.decode(ETSketchData.self, forKey: .payload))
        case .tap:
            self = .tap(try container.decode(ETTapData.self, forKey: .payload))
        case .video:
            self = .video(try container.decode(ETVideoData.self, forKey: .payload))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.type, forKey: .type)
        
        switch self {
        case .anger(let item):
            try container.encode(item, forKey: .payload)
        case .heartbeat(let item):
            try container.encode(item, forKey: .payload)
        case .kiss(let item):
            try container.encode(item, forKey: .payload)
        case .sketch(let item):
            try container.encode(item, forKey: .payload)
        case .tap(let item):
            try container.encode(item, forKey: .payload)
        case .video(let item):
            try container.encode(item, forKey: .payload)
        }
    }
}
