//
//  RichLinkStyle.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

enum RichLinkStyle: Int, Codable {
    case media = 0
    case plain = 1
    case unknown = 2
    case twitter = 3
    case custom = 5
    
    init?(_ rawValue: Int) {
        switch rawValue {
        case 0:
            self = .media
        case 1:
            self = .plain
        case 2:
            self = .unknown
        case 3:
            self = .twitter
        case 5:
            self = .custom
        default:
            return nil
        }
    }
    
    var id: String {
        switch self {
        case .media: return "media"
        case .plain: return "plain"
        case .unknown: return "unknown"
        case .twitter: return "twitter"
        case .custom: return "custom"
        }
    }
}
