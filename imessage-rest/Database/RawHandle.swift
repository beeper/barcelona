//
//  RawHandle.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

/**
 Represents the handle table in the chat.db file
 */
class RawHandle: Record {
    override class var databaseTableName: String { "handle" }
    
    required init(row: Row) {
        country = row[Columns.country]
        id = row[Columns.id]
        person_centric_id = row[Columns.person_centric_id]
        ROWID = row[Columns.ROWID]
        service = row[Columns.service]
        uncanonicalized_id = row[Columns.uncanonicalized_id]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.country] = country
        container[Columns.id] = id
        container[Columns.person_centric_id] = person_centric_id
        container[Columns.ROWID] = ROWID
        container[Columns.service] = service
        container[Columns.uncanonicalized_id] = uncanonicalized_id
    }
    
    enum Columns: String, ColumnExpression {
        case country, id, person_centric_id, ROWID, service, uncanonicalized_id
    }
    
    var country: String?
    var id: String?
    var person_centric_id: String?
    var ROWID: Int64?
    var service: String?
    var uncanonicalized_id: String?
}
