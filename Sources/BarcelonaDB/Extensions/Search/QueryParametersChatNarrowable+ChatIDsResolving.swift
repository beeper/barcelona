//
//  QueryParametersChatNarrowable+ChatIDsResolving.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation

internal extension QueryParametersChatNarrowable {
    func chatROWIDs() -> Promise<[Int64]> {
        if let chats = chats, chats.count > 0 {
            return DBReader.shared.rowIDs(forIdentifiers: chats).values.flatten()
        } else {
            return .success([])
        }
    }
}
