//
//  InternalAttachment+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import BarcelonaDB
import Foundation

// MARK: - Begin Deprecated
extension RawAttachment {
    @usableFromInline
    var attachment: Attachment? {
        guard let guid = guid, let path = filename as NSString? else {
            return nil
        }

        return Attachment(
            mime: mime_type,
            filename: path.expandingTildeInPath,
            id: guid,
            uti: uti,
            origin: origin,
            size: nil,
            sticker: nil
        )
    }
}
// MARK: - End Deprecated
