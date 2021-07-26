//
//  IMMessage+LazilyIdentifiable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMMessage: Identifiable {
    public var id: String {
        guid
    }
}
