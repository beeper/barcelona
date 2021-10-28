//
//  IMFileTransfer+AutoDownload.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/27/21.
//

import Foundation
import IMSharedUtilities
import IMFoundation

public extension IMFileTransfer {
    /// Whether the transfer will automatically be downloaded by imagent
    var canAutoDownload: Bool {
        var x = ObjCBool(false) // we dont care about the inout value it provides
        
        return IMiMessageMaxFileSizeForUTI(type, &x) > totalBytes
    }
}
