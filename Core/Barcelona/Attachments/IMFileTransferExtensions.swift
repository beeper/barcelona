//
//  IMFileTransferExtensions.swift
//  Barcelona
//
//  Created by Joonas Myhrberg on 24.4.2023.
//

import Foundation
import IMCore
import Logging

extension IMFileTransfer {

    public var log: Logging.Logger {
        Logger(label: "IMFileTransfer")
    }

    public var inSandboxedLocation: Bool {
        log.debug("checking inSandboxedLocation for localPath: \(localPath as String?)")
        return localPath.hasPrefix("/var/folders")
    }

    public var isTrulyFinished: Bool {
        isFinished && existsAtLocalPath && !inSandboxedLocation
    }

    public var needsUnpurging: Bool {
        state == .waitingForAccept && canAutoDownload && CBPurgedAttachmentController.maxBytes > totalBytes
    }
}

extension IMFileTransfer {
    var actualState: IMFileTransferState {
        let state = state
        if state == .error, error == 24, existsAtLocalPath {
            // i have no clue what is going on but the attachment is present and usable
            log.debug("have error 24, treating as finished")
            return .finished
        }
        return state
    }
}
