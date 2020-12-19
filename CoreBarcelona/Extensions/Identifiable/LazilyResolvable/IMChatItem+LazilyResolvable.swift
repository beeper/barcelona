//
//  IMChatItem+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 12/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO

extension IMChatItem: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifiers identifiers: [String], on eventLoop: EventLoop?) -> EventLoopFuture<[IMChatItem]> {
        
        let messageIdentifiers: [String] = identifiers.compactMap {
            $0.split(separator: ":").last?.split(separator: "/").last
        }.map {
            String($0)
        }
        
        return IMMessage.lazyResolve(withIdentifiers: messageIdentifiers, on: eventLoop).map {
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
