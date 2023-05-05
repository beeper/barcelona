//
//  IMFileTransfer+AutoDownload.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/27/21.
//

import Foundation
import IMCore
import IMFoundation
import IMSharedUtilities

extension IMFileTransfer {
    /// Whether the transfer will automatically be downloaded by imagent
    public var canAutoDownload: Bool {
        var x = ObjCBool(false)  // we dont care about the inout value it provides

        return IMiMessageMaxFileSizeForUTI(type, &x) > totalBytes
    }
}
