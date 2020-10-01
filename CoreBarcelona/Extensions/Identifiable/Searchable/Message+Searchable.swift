//
//  Message+Searchable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO

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
    public static func resolve(withParameters parameters: MessageQueryParameters, on eventLoop: EventLoop?) -> EventLoopFuture<[Message]> {
        DBReader(eventLoop: eventLoop ?? messageQuerySystem.next()).queryMessages(withParameters: parameters)
    }
}
