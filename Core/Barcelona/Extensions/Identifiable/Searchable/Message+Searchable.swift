//
//  Message+Searchable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaDB

extension Message: Searchable {
    public static func resolve(withParameters parameters: MessageQueryParameters) -> Promise<[Message]> {
        DBReader.shared.queryMessages(withParameters: parameters)
            .then {
                BLLoadChatItems($0)
            }.compactMap { $0 as? Message }
    }
}
