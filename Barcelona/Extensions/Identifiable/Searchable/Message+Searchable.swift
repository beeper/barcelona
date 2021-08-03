//
//  Message+Searchable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public struct MessageQueryParameters: QueryParameters {
    public var search: String?
    public var bundle_id: String?
    
    public var chats: [String]?
    public var handles: [String]?
    public var contacts: [String]?
    public var from_me: Bool?
    
    public var limit: Int?
    public var page: Int?
}

extension Message: Searchable {
    public static func resolve(withParameters parameters: MessageQueryParameters) -> Promise<[Message]> {
        DBReader.shared.queryMessages(withParameters: parameters)
            .then {
                BLLoadChatItems($0)
            }.compactMap { $0 as? Message }
    }
}
