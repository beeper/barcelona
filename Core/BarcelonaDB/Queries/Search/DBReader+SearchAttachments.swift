//
//  DBReader+SearchAttachments.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import BarcelonaFoundation
import Foundation
import GRDB

#if canImport(IMCore)
import IMCore

private class IMServiceRegistrationProviderImpl: IMServiceRegistrationProvider {
    static let shared = IMServiceRegistrationProviderImpl()

    func handle(forService service: String) -> String? {
        IMAccountController.__sharedInstance().bestAccount(forService: service)?.loginIMHandle?.id
    }
}
#endif
