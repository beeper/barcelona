//
//  IMChatItem+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 12/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public extension String {
    var cb_messageIDExtracted: String? {
        guard let splitted = self.split(separator: ":").last?.split(separator: "/").last else {
            return nil
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
