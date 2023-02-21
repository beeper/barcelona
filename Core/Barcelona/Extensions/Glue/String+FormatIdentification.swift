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
extension String {
    public var isEmail: Bool {
        IMStringIsEmail(self)
    }

    public var isBusinessID: Bool {
        IMStringIsBusinessID(self)
    }

    public var isPhoneNumber: Bool {
        IMStringIsPhoneNumber(self)
    }

    public var style: HandleIDStyle {
        switch true {
        case isEmail: return .email
        case isPhoneNumber: return .phoneNumber
        case isBusinessID: return .businessID
        default: return .unknown
        }
    }
}
