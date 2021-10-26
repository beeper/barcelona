//
//  Structs.swift
//  BarcelonaDB
//
//  Created by Eric Rabil on 8/4/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public protocol QueryParameters: Codable {
    var limit: Int? { get set }
    var page: Int? { get set }
}

public protocol QueryParametersChatNarrowable: QueryParameters {
    var chats: [String]? { get }
}

public struct AttachmentSearchParameters: QueryParameters, QueryParametersChatNarrowable {
    /// mime and likeMIME are mutually exclusive
    public var mime: [String]?
    public var likeMIME: String?
    /// uti and likeUTI are mutually exclusive
    public var uti: [String]?
    public var likeUTI: String?
    
    public var name: String?
    public var chats: [String]?
    public var limit: Int?
    public var page: Int?
}

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
