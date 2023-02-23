//
//  BLTest.swift
//  barcelona
//
//  Created by Eric Rabil on 4/15/22.
//

import Barcelona
import BarcelonaIPC
import BarcelonaMautrixIPC
import IMCore
import XCTest

class SmokeTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    public func testBlocked() {
        let blockExpectation = expectation(description: "Blocked message")
        blockExpectation.isInverted = true
        let id = UUID().uuidString
        BLBlocklistController.shared.testingOverride.insert("+123456")
        BLPayloadIntercept = { payload in
            if case .message(let message) = payload.command {
                if message.guid == id {
                    blockExpectation.fulfill()
                }
            }
        }
        BLEventHandler.shared.receiveMessage(
            Message.init(
                id: id,
                chatID: id,
                fromMe: false,
                time: 0,
                sender: "+123456",
                isSOS: false,
                isTypingMessage: false,
                isCancelTypingMessage: false,
                isDelivered: true,
                isAudioMessage: false,
                flags: .finished,
                failed: false,
                failureCode: .noError,
                failureDescription: "",
                items: [],
                service: .iMessage,
                fileTransferIDs: []
            )
        )
        wait(for: [blockExpectation], timeout: 3)
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
