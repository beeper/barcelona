//
//  IMService+Identifiable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMService: Identifiable {
    public var id: IMServiceStyle? {
        switch self {
        case IMService.iMessage(): return .iMessage;
        case IMService.facetime(): return .FaceTime;
        case IMService.call(): return .Phone;
        case IMService.sms(): return .SMS;
        default: return nil
        }
    }
}
