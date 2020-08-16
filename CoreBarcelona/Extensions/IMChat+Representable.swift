//
//  IMChat+Representable.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChat {
    var representation: Chat {
        Chat(self)
    }
    
    var representableParticipantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participantHandleIDs())
    }
}
