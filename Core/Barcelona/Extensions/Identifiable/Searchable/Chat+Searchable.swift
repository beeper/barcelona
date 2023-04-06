//
//  Chat+Searchable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import BarcelonaDB
import Foundation
import IMCore
import IMFoundation

#if DEBUG
import os.log
#endif

extension IMChatJoinState: Codable {
    public init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(RawValue.self)

        guard let state = IMChatJoinState(rawValue: rawValue) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid IMChatJoinState", underlyingError: nil)
            )
        }

        self = state
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension Array where Element: Equatable {
    func contains(items: [Element]) -> Bool {
        items.allSatisfy {
            self.contains($0)
        }
    }
}
