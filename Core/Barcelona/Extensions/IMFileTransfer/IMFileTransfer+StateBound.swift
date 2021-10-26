//
//  IMFileTransfer+StateBound.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/10/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public extension IMFileTransfer {
    enum IMFileTransferState: Int64 {
        case archiving = 0
        case waitingForAccept = 1
        case accepted = 2
        case preparing = 3
        case transferring = 4
        case finalizing = 5
        case finished = 6
        case error = 7
        case recoverableError = 8
        case unknown
        
        fileprivate init(transfer: IMFileTransfer) {
            self = .init(rawValue: transfer.value(forKey: "transferState") as! Int64) ?? .unknown
        }
    }
    
    var state: IMFileTransferState {
        IMFileTransferState(transfer: self)
    }
}
