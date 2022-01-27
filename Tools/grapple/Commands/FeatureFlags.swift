//
//  FeatureFlags.swift
//  barcelona
//
//  Created by Eric Rabil on 1/27/22.
//

import Foundation
import SwiftCLI
import Barcelona

extension FeatureFlag {
    var prettyPath: String {
        domain.rawValue + "." + key
    }
}

class FeatureFlags: CommandGroup {
    let name = "flags"
    let shortDescription = "manage feature flags"
    
    class ListFeatureFlags: Command {
        let name = "list"
        
        func execute() throws {
            CBFeatureFlags.allFlags.sorted(usingKey: \.prettyPath, by: >).forEach { flag in
                print(flag)
            }
            exit(0)
        }
    }
    
    class SetFeatureFlag: Command {
        let name = "set"
        
        @Param var domain: String
        @Param var key: String
        @Param var value: Bool
        
        func execute() throws {
            guard var flag = CBFeatureFlags.allFlags.first(where: { flag in
                flag.domain.rawValue == domain && flag.key == key
            }) else {
                print("?")
                exit(0)
            }
            flag.wrappedValue = value
        }
    }
    
    class UnsetFeatureFlag: Command {
        let name = "unset"
        
        @Param var domain: String
        @Param var key: String
        
        func execute() throws {
            guard let flag = CBFeatureFlags.allFlags.first(where: { flag in
                flag.domain.rawValue == domain && flag.key == key
            }) else {
                print("?")
                exit(0)
            }
            flag.unset()
        }
    }
    
    var children: [Routable] = [
        ListFeatureFlags(), SetFeatureFlag(), UnsetFeatureFlag()
    ]
}
