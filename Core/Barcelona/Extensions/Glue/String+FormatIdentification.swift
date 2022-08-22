//
//  String+FormatIdentification.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMFoundation

/// Helper variables when processing string IDs into IDS destinations
public extension String {
    var isEmail: Bool {
        IMStringIsEmail(self)
    }
    
    var isBusinessID: Bool {
        IMStringIsBusinessID(self)
    }
    
    var isPhoneNumber: Bool {
        IMStringIsPhoneNumber(self)
    }
    
    var style: HandleIDStyle {
        switch true {
        case isEmail: return .email
        case isPhoneNumber: return .phoneNumber
        case isBusinessID: return .businessID
        default: return .unknown
        }
    }
}
