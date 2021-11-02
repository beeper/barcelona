//
//  IMChat+ChatStyle.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public extension IMChat {
    var isGroup: Bool {
        chatStyle == .group
    }
    
    var isSingle: Bool {
        chatStyle == .instantMessage
    }
}
