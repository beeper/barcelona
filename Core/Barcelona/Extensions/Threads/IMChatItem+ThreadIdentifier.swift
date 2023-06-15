//
//  ChatItemRepresentation+CreateThreadIdentifier.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 12/17/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChatItem {
    @available(macOS 10.16, *)
    public static func resolveThreadIdentifier(
        forMessageWithGUID guid: String,
        part: Int,
        onService service: IMServiceStyle
    ) -> String? {
        guard let subpart = BLLoadIMMessage(withGUID: guid, onService: service)?.subpart(at: part) as? IMMessagePartChatItem else {
            return nil
        }

        return subpart.threadIdentifier() ?? IMCreateThreadIdentifierForMessagePartChatItem(subpart)
    }
}
