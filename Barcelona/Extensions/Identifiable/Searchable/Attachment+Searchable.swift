//
//  Attachment+Searchable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaDB

extension Attachment: Searchable {
    public static func resolve(withParameters parameters: AttachmentSearchParameters) -> Promise<[Attachment]> {
        DBReader.shared.attachments(matchingParameters: parameters).compactMap(\.attachment)
    }
}
