//
//  DBReader+SearchMessages-Complex.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB
import Logging

#if canImport(IMCore)
import IMCore

extension IMHandleRegistrar: IMCNHandleBridgingProvider {
    public func handleIDs(forCNIdentifier arg1: String) -> [String] {
        handles(forCNIdentifier: arg1).map(\.id)
    }

    public var allLoginHandles: [String] {
        IMAccountController.__sharedInstance().accounts.flatMap(\.aliases)
    }
}
#endif

extension DBReader {
    public var log: Logging.Logger {
        Logger(label: "DBReader")
    }
}
