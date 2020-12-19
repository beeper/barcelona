//
//  ChatItemRepresentation+CreateThreadIdentifier.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 12/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO

extension IMChatItem {
    @available(iOS 14, macOS 10.16, watchOS 7, *)
    public static func resolveThreadIdentifier(forIdentifier identifier: String, on eventLoop: EventLoop?) -> EventLoopFuture<String?> {
        return lazyResolve(withIdentifier: identifier, on: eventLoop).map {
            guard let partChatItem = $0 as? IMMessagePartChatItem else {
                return nil
            }
            
            return IMCreateThreadIdentifierForMessagePartChatItem(partChatItem)
        }
    }
}
