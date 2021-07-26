//
//  InternalAttachment+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

extension InternalAttachment: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifiers identifiers: [String]) -> Promise<[InternalAttachment], Error> {
        DBReader(pool: databasePool).attachments(withGUIDs: identifiers)
    }
}
