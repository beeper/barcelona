//
//  Message+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

extension Message: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifiers identifiers: [String]) -> Promise<[Message]> {
        lazyResolve(withIdentifiers: identifiers.compactMap { $0 }, inChat: nil)
    }
    
    public static func lazyResolve(withIdentifiers identifiers: [String], inChat chat: String?) -> Promise<[Message]> {
        messages(withGUIDs: identifiers, in: chat)
    }
}
