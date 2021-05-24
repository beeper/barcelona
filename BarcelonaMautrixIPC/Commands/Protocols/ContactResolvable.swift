//
//  ContactResolvable.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import CoreBarcelona

public protocol ContactResolvable {
    var user_guid: String { get set }
}

public extension ContactResolvable {
    var contact: CNContact? {
        CNContact.resolve(withIdentifier: user_guid)
    }
}
