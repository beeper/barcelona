//
//  Searchable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import NIO

/// Represents an identifiable and searchable record/entity
public protocol Searchable: Identifiable {
    /// Applicable search parameters
    associatedtype QueryParametersImplementation: QueryParameters
    /// Metatype for instance type of implementation
    associatedtype instancetype: Codable
    /// Represents the bulk version of the search parameters
    associatedtype BulkSearch = BulkSearchRequest<QueryParametersImplementation>
    
    /// Perform a single query
    static func resolve(withParameters: QueryParametersImplementation, on eventLoop: EventLoop?) -> EventLoopFuture<[instancetype]>
    /// Perform multiple concurrent queries
    static func bulkResolve(withParameters: BulkSearch, on eventLoop: EventLoop?) -> EventLoopFuture<[String: [instancetype]]>
}

/// Implementation for concurrent bulk searches
extension Searchable {
    /// Concurrently executes all provided queries, returning a dictionary keyed identical to the parameters, with the result values replacing the query values
    public static func bulkResolve(withParameters parameters: [String: QueryParametersImplementation], on eventLoop: EventLoop?) -> EventLoopFuture<[String: [instancetype]]> {
        let eventLoop = eventLoop ?? messageQuerySystem.next()
        
        return EventLoopFuture<(String, [instancetype])>.whenAllSucceed(parameters.map { entry in
            self.resolve(withParameters: entry.value, on: nil).map {
                (entry.key, $0)
            }
        }, on: eventLoop).map {
            $0.reduce(into: [String: [instancetype]]()) { ledger, results in
                ledger[results.0] = results.1
            }
        }
    }
}

/// Represents a bulk search request
public protocol BulkSearchRequestRepresentable: Codable {
    associatedtype T: QueryParameters
    
    /// Search queries keyed by unique IDs to be used in the results
    var searches: [String: T] { get set }
}

public struct BulkSearchRequest<T: QueryParameters>: BulkSearchRequestRepresentable {
    public var searches: [String: T]
}

public protocol QueryParameters: Codable {
    var limit: Int? { get set }
    var page: Int? { get set }
}

public protocol SearchParameter {
    associatedtype Object
    
    func test(_ object: Object) -> Bool
}

public extension Array where Element : SearchParameter {
    typealias Object = Element.Object
    
    func test(_ object: Object) -> Bool {
        allSatisfy {
            $0.test(object)
        }
    }
}

public protocol QueryParametersChatNarrowable: QueryParameters {
    var chats: [String]? { get }
}

extension QueryParametersChatNarrowable {
    func chatROWIDs() -> EventLoopFuture<[Int64]> {
        if let chats = chats, chats.count > 0 {
            return DBReader.shared.rowIDs(forIdentifiers: chats).map {
                $0.values.flatMap {
                    $0
                }
            }
        } else {
            return messageQuerySystem.next().makeSucceededFuture([])
        }
    }
}
