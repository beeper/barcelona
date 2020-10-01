//
//  SearchAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona
import NIO
import IMCore
import Vapor

/// Represents a bulk search resolution
struct BulkSearchResult<T: Codable>: Codable {
    /// Results keyed using the key<->params object
    var results: [String: [T]]
}

/// Represents a search resolution
struct SearchResult<T: Codable>: Codable {
    /// Results from the search query
    var results: [T]
}

extension BulkSearchResult: Content {}
extension SearchResult: Content {}

private func BulkSearchEndpoint<P: Searchable>(clazz: P.Type) -> (Request) throws -> EventLoopFuture<BulkSearchResult<P.instancetype>> {
    return { req in
        guard let parameters = try? req.content.decode(BulkSearchRequest<P.QueryParametersImplementation>.self) else {
            throw Abort(.badRequest, reason: "Malformed search request")
        }
        
        return clazz.bulkResolve(withParameters: parameters.searches, on: req.eventLoop).map {
            BulkSearchResult(results: $0)
        }
    }
}

private func SingleSearchEndpoint<P: Searchable>(clazz: P.Type) -> (Request) throws -> EventLoopFuture<SearchResult<P.instancetype>> {
    return { req in
        guard let parameters = try? req.query.decode(P.QueryParametersImplementation.self) else {
            throw Abort(.badRequest, reason: "Malformed search request")
        }
        
        return clazz.resolve(withParameters: parameters, on: req.eventLoop).map {
            SearchResult(results: $0)
        }
    }
}

public func bindSearchAPI(_ app: RoutesBuilder) {
    #if BARCELONA_UNIFIED_SEARCH
    let search = app.grouped("search")
    #endif
    
    func attach<P: Searchable>(searchEndpointClass: P.Type, grant: TokenGrant, forPath path: String) {
        #if BARCELONA_UNIFIED_SEARCH
        let group = search.grouped(PathComponent(stringLiteral: path)).grouped(grant)
        #else
        let group = app.grouped(PathComponent(stringLiteral: path)).grouped("search").grouped(grant)
        #endif
        
        group.get(use: SingleSearchEndpoint(clazz: searchEndpointClass))
        group.post("bulk", use: BulkSearchEndpoint(clazz: searchEndpointClass))
    }
    
    attach(searchEndpointClass: Message.self, grant: .readMessages, forPath: "messages")
    attach(searchEndpointClass: Attachment.self, grant: .readAttachments, forPath: "attachments")
    attach(searchEndpointClass: Chat.self, grant: .readChats, forPath: "chats")
    attach(searchEndpointClass: Contact.self, grant: .readContacts, forPath: "contacts")
}
