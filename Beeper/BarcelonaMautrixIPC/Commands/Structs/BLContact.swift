//
//  BLContact.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Contacts
import Barcelona

private func ensuredPrefix(_ handleID: String, withService service: String) -> String {
    if handleID.split(separator: ";").count == 3 {
        return handleID
    } else {
        return service + ";-;" + (handleID.split(separator: ";").last ?? handleID[...])
    }
}

import BarcelonaMautrixIPCProtobuf

public typealias BLContact = PBContact

private extension BLContactSuggestionData {
    var imageData: Data? {
        guard let image = image else {
            return nil
        }
        
        return try? Data(contentsOf: image)
    }
}

public extension BLContact {
    init(suggestion: BLContactSuggestionData, phoneHandles: [String], emailHandles: [String], handleID: PBGUID) {
        self = .with {
            suggestion.firstName.oassign(to: &$0.firstName)
            suggestion.lastName.oassign(to: &$0.lastName)
            suggestion.displayName.oassign(to: &$0.nickname)
            suggestion.imageData.oassign(to: &$0.avatar)
            $0.phones = phoneHandles
            $0.emails = emailHandles
            $0.userGuid = handleID
        }
    }
}
