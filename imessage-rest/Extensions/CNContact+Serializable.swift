//
//  CNContact+Serializable.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Contacts

extension CNContact {
    func serialized() -> Data? {
        do {
            return try CNContactVCardSerialization.data(with: [self])
        } catch {
            return nil
        }
    }
    
    func serializedString() -> String? {
        guard let data = serialized() else { return nil }
        return String(data: data, encoding: .utf8);
    }
}
