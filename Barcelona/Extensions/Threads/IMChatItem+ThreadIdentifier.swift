//
//  ChatItemRepresentation+CreateThreadIdentifier.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 12/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChatItem {    
    @available(iOS 14, macOS 10.16, watchOS 7, *)
    public static func resolveThreadIdentifier(forIdentifier identifier: String) -> Promise<String?, Error> {
        return lazyResolve(withIdentifier: identifier).then { item in
            guard let partChatItem = item as? IMMessagePartChatItem else {
                return nil
            }
            
            return IMCreateThreadIdentifierForMessagePartChatItem(partChatItem)
        }
    }
}
