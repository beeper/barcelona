//
//  Result.swift
//  Extensions
//
//  Created by June Welker on 5/29/23.
//

import Foundation

public extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}
