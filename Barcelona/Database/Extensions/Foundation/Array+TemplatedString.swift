//
//  Array+TemplatedString.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

internal extension Array {
    var templatedString: String {
        map { _ in
            "?"
        }.joined(separator: ", ")
    }
}
