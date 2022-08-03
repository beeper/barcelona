//
//  RegressionTesting.swift
//  grapple
//
//  Created by Eric Rabil on 8/3/22.
//

import Foundation
import SwiftCLI
import Barcelona
import BarcelonaMautrixIPC

class RegressionTestingCommand: CommandGroup {
    let name = "rgt"
    let shortDescription = "reproducible tests for specific tickets"
    
    class BarcelonaRG: EphemeralBarcelonaCommand {
        let name = "bl"
        let shortDescription = "regression tests for barcelona"
        
        @CollectedParam var ids: [String]
        
        func execute() throws {
            if ids.isEmpty {
                print(Barcelona.BLRegressionTesting.tests.keys.map { "- \($0)" }.joined(separator: "\n"))
                exit(0)
            }
            for id in ids {
                guard let test = Barcelona.BLRegressionTesting.tests[id.uppercased()] else {
                    print("skipping \(id): unknown test")
                    continue
                }
                test()
            }
        }
    }
    
    class MautrixRG: EphemeralBarcelonaCommand {
        let name = "mx"
        let shortDescription: String = "regression tests for the mautrix layer"
        
        @CollectedParam var ids: [String]
        
        func execute() throws {
            if ids.isEmpty {
                print(BarcelonaMautrixIPC.RegressionTesting.tests.keys.map { "- \($0)" }.joined(separator: "\n"))
                exit(0)
            }
            for id in ids {
                guard let test = BarcelonaMautrixIPC.RegressionTesting.tests[id.uppercased()] else {
                    print("skipping \(id): unknown test")
                    continue
                }
                test()
            }
        }
    }
    
    let children: [Routable] = [BarcelonaRG(), MautrixRG()]
}
