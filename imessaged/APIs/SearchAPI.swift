//
//  SearchAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor

public func bindSearchAPI(_ app: Application) {
    let search = app.grouped("search")
    
    /**
     Search global messages
     */
    search.get("messages") { req -> EventLoopFuture<BulkSearchResultRepresentation> in
        let query = (try? req.query.get(String.self, at: "query")) ?? "", limit = try? req.query.get(Int.self, at: "limit")
        
        return DBReader(pool: db, eventLoop: req.eventLoop).messages(matching: query, limit: limit ?? 20)
    }
}
