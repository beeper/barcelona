//
//  IMChatItem+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 12/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public struct CBMessageItemIdentifierData: Codable, CustomStringConvertible, RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue.first {
        case "t":
            return nil
        case "p":
            // part
            let rawParsed = rawValue[rawValue.index(after: rawValue.firstIndex(of: ":")!)...].split(separator: "/")
            
            id = String(rawParsed[1])
            part = Int(String(rawParsed[0]))
            type = "p"
        default:
            // transcript
            type = String(rawValue[rawValue.startIndex ..< rawValue.firstIndex(of: ":")!])
            
            let components = rawValue[rawValue.index(after: rawValue.firstIndex(of: ":")!)...].split(separator: "/")
            
            guard let id = components.first else {
                return nil
            }
            
            self.id = String(id)
            additionalData = components[1...].map { String($0) }
        }
    }
    
    public var rawValue: String {
        description
    }
    
    public typealias RawValue = String
    
    public var id: String
    public var part: Int?
    public var additionalData: [String]?
    public var type: String?
    
    private var partString: String {
        guard let part = part else {
            return ""
        }
        
        return "\(part):"
    }
    
    private var typeString: String {
        guard let type = type else {
            return ""
        }
        
        return "\(type)/"
    }
    
    public var description: String {
        partString + typeString + id
    }
}

public extension String {
    var cb_messageIDExtracted: String {
        guard let splitted = self.split(separator: ":").last?.split(separator: "/").last else {
            return self
        }
        
        return String(splitted)
    }
}

extension IMChatItem: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifiers identifiers: [String]) -> Promise<[IMChatItem], Error> {
        let messageIdentifiers: [String] = identifiers.compactMap {
            $0.cb_messageIDExtracted
        }.map {
            String($0)
        }
        
        return IMMessage.lazyResolve(withIdentifiers: messageIdentifiers).then {
            $0.flatMap {
                $0._imMessageItem._newChatItems().filter {
                    guard let transcriptChatItem = $0 as? IMTranscriptChatItem, identifiers.contains(transcriptChatItem.guid) else {
                        return false
                    }
                    return true
                }
            }
        }
    }
}
