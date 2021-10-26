//
//  String+Service.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public extension String {
    var service: IMService? {
        Registry.sharedInstance.resolve(service: self)
    }
}
