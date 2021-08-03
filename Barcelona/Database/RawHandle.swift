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
public class RawHandle: Record {
    public override class var databaseTableName: String { "handle" }
    
    public required init(row: Row) {
        country = row[Columns.country]
        id = row[Columns.id]
        person_centric_id = row[Columns.person_centric_id]
        ROWID = row[Columns.ROWID]
        service = row[Columns.service]
        uncanonicalized_id = row[Columns.uncanonicalized_id]
        super.init(row: row)
    }
    
    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.country] = country
        container[Columns.id] = id
        container[Columns.person_centric_id] = person_centric_id
        container[Columns.ROWID] = ROWID
        container[Columns.service] = service
        container[Columns.uncanonicalized_id] = uncanonicalized_id
    }
    
    public enum Columns: String, ColumnExpression {
        case country, id, person_centric_id, ROWID, service, uncanonicalized_id
    }
    
    public var country: String?
    public var id: String
    public var person_centric_id: String?
    public var ROWID: Int64?
    public var service: String?
    public var uncanonicalized_id: String?
}
