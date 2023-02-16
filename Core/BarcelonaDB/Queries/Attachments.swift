//
//  Attachments.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB
import BarcelonaFoundation

public extension DBReader {
    func attachment(for guid: String) async throws -> RawAttachment? {
        return try await attachments(withGUIDs: [guid]).first
    }
    
    func attachments(withGUIDs guids: [String]) async throws -> [RawAttachment] {
        log.debug("DBReader selecting attachments with GUIDs \(guids)")
        
        if guids.count == 0 { return [] }
        
        return try await read { db in
            try RawAttachment
                .filter(guids.contains(RawAttachment.Columns.guid) || guids.contains(RawAttachment.Columns.original_guid))
                .fetchAll(db)
        }
    }
}
