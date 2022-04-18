//
//  BLTest.swift
//  barcelona
//
//  Created by Eric Rabil on 4/15/22.
//

import XCTest
import IMCore
import BarcelonaMautrixIPC
@testable import barcelona_mautrix_test_dummy
import Barcelona

class SmokeTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    public func testContacts() {
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 10
        
        var omitAvatars = false, asyncLoad = false
        measure(metrics: [XCTClockMetric()], options: measureOptions) {
            let expectation = expectation(description: "finished")
            DispatchQueue.global(qos: .utility).async {
                defer {
                    if omitAvatars && asyncLoad {
                        omitAvatars = false
    //                    asyncLoad = true
                    } else if !omitAvatars && asyncLoad {
    //                    omitAvatars = false
                        asyncLoad = false
                    } else if !omitAvatars && !asyncLoad {
                        omitAvatars = true
    //                    asyncLoad = false
                    } else if omitAvatars && !asyncLoad {
                        omitAvatars = true
                        asyncLoad = true
                    }
                    expectation.fulfill()
                }
                print("BMXGenerateContactList(omitAvatars: \(omitAvatars), asyncLookup: \(asyncLoad)).count == ", BMXGenerateContactList(omitAvatars: omitAvatars, asyncLookup: asyncLoad).count)
            }
            wait(for: [expectation], timeout: 15)
        }
    }
}

class MessageIntegrityTests: XCTestCase {
    class override func setUp() {
        guard BLSetup() else {
            fatalError("Can't setup Barcelona")
        }
    }
    
    class override func tearDown() {
        BLTeardown()
    }
    
    func testASDF() throws {
        
        
    }
}
