//
//  Attachments.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

public extension DBReader {
    func attachment(for guid: String) -> Promise<RawAttachment?> {
        return attachments(withGUIDs: [guid]).first
    }
    
    func attachments(withGUIDs guids: [String]) -> Promise<[RawAttachment]> {
        DBLog.debug("DBReader selecting attachments with GUIDs %@", guids)
        
        if guids.count == 0 { return .success([]) }
        
        return read { db in
            try RawAttachment
                .filter(guids.contains(RawAttachment.Columns.guid) || guids.contains(RawAttachment.Columns.original_guid))
                .fetchAll(db)
        }
    }
}
