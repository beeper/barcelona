//
//  IMChatItem+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 12/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension String {
    fileprivate var unpacked: (type: String?, part: Int?, id: String) {
        guard let slashIndex = firstIndex(of: "/"), let colonIndex = firstIndex(of: ":") else {
            guard let colonIndex = firstIndex(of: ":") else {
                return (nil, nil, self)
            }

            let type = self[..<colonIndex]
            let id = self[index(after: colonIndex)...]

            return (String(type), nil, String(id))
        }

        let type = self[..<colonIndex]
        let part = self[index(after: colonIndex)..<slashIndex]
        let id = self[index(after: slashIndex)...]

        return (String(type), Int(part), String(id))
    }
}

public struct CBMessageItemIdentifierData: Codable, CustomStringConvertible, RawRepresentable {
    public init?(rawValue: String) {
        guard let character = rawValue.first, character != "t" else {
            return nil
        }

        (type, part, id) = rawValue.unpacked
    }

    public var rawValue: String {
        description
    }

    public typealias RawValue = String

    public var id: String
    public var part: Int?
    public var type: String?

    public var description: String {
        [
            type.map {
                $0.appending(":")
            } ?? "",
            part.map {
                $0.description.appending("/")
            } ?? "",
            id,
        ]
        .joined(separator: "")
    }
}
