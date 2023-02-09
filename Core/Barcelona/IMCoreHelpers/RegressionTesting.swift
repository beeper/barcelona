//
//  RegressionTesting.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/2/22.
//

import Foundation

public struct BLRegressionTesting {
}

public extension BLRegressionTesting {
    /// Change me before running
    static var validMailtoURI: String = "mailto:info@orders.apple.com"
    /// Change me before running
    static var validTelURI: String = "tel:+15555555555"
    
    static var uris: [String] {
        [validMailtoURI, validTelURI]
    }
    
    static var unprefixedURIs: [String] {
        uris.map(\.fastDroppingURIPrefix)
    }
    
    static var handles: [IMHandle] {
        IMAccountController.shared.activeAccounts!.filter { $0.service?.id != .FaceTime }.flatMap { account in
            unprefixedURIs.compactMap {
                account.imHandle(withID: $0)
            }
        }
    }
}

// Testing methods
@MainActor
fileprivate extension IMChat {
    func forceToSMS() {
        _setAccount(IMAccountController.shared.activeSMSAccount, locally: false)
        guard willSendSMS else {
            preconditionFailure("Attempted to force IMChat to send over SMS, but account did not change to SMS.")
        }
    }
}

import IMCore

@MainActor
public extension BLRegressionTesting {
    static let tests: [String: () -> ()] = [
        "BRI4482": BRI4482,
        "BRI4462": BRI4462,
        "ChatRegistryPerf": {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global().async {
                let queue = OperationQueue()
                queue.underlyingQueue = .global()
                queue.maxConcurrentOperationCount = 10
                for chat in CBChatRegistry.shared.allChats.values {
                    queue.schedule {
                        let group = DispatchGroup()
                        group.enter()
                        DispatchQueue.main.async {
                            print(">>> Raw history query for \(chat.chatIdentifiers.joined(separator: ","))")
                            chat.rawHistoryQuery(limit: 10).forEach { chat, message in
                                guard chat.scheme == .chatIdentifier else {
                                    preconditionFailure()
                                }
                                // here we can just try both iMessage and SMS and see if either of them comes up with a valid chat
                                // since we don't really care about being super efficient and correct (or else we'd find some way
                                // to query from the DB the service that they're on).
                                let iMessage = Message(messageItem: message, chatID: chat.value, service: .iMessage)
                                let sms = Message(messageItem: message, chatID: chat.value, service: .SMS)

                                if iMessage.imChat == nil && sms.imChat == nil {
                                    preconditionFailure("Failed to resolve IMChat[\(chat.scheme):\(chat.value)] for message \(message.id)")
                                }
                            }.always { result in
                                if case .failure(let error) = result {
                                    preconditionFailure("Failed to do history query on on chat \(chat.IMChats.map(\.debugDescription))")
                                } else {
                                    print(">>> Raw history query for \(chat.chatIdentifiers.joined(separator: ",")) completed")
                                }
                                group.leave()
                            }
                        }
                        group.wait()
                    }
                }
                queue.waitUntilAllOperationsAreFinished()
                semaphore.signal()
            }
            while true {
                switch semaphore.wait(timeout: .now()) {
                case DispatchTimeoutResult.timedOut:
                    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.250))
                case DispatchTimeoutResult.success:
                    return
                }
            }
        },
        "iChatForSending": {
            let guid = ProcessInfo.processInfo.environment["CHAT_GUID"]!
            let chat = CBChatRegistry.shared.chats[.guid(guid)]!
            print(chat.chatForSending(with: guid).debugDescription)
        },
        "sChatForSending": {
            let guid = ProcessInfo.processInfo.environment["CHAT_GUID"]!
            let chat = CBChatRegistry.shared.chats[.guid(guid)]!
            print(chat.chatForSending(with: guid).debugDescription)
        }
    ]

    static func BRI4482() {
        guard let smsEmailHandle = handles.first(where: {
            $0.id.isEmail && $0.service?.id == .SMS
        }) else {
            preconditionFailure("Expected to find an SMS email handle, but did not.")
        }
        
        let chat = IMChatRegistry.shared.chat(for: smsEmailHandle)
        chat._setAccount(smsEmailHandle.account, locally: true)
        guard chat.willSendSMS else {
            preconditionFailure("Expected chat to be SMS targeted initially")
        }
        let wrapper = Chat(chat)
        try! wrapper.send(message: .init(parts: [.init(type: .text, details: "asdf")]))
    }
    
    /// Coverage for the case where an SMS chat is pointed at an e-mail
    static func BRI4462() {
        enum Outcome {
            case fail
            case succeed
        }
        
        let handles = handles
        
        func go_barcelona(_ outcome: Outcome) {
            // hunt down the SMS email handle
            guard let smsEmailHandle = handles.first(where: {
                $0.id.isEmail && $0.service?.id == .SMS
            }) else {
                preconditionFailure("Expected to find an SMS email handle, but did not.")
            }
            guard let bestHandle = IMHandle.bestIMHandle(in: handles) else {
                preconditionFailure("Expected to find the best handle from a set of handles, but did not.")
            }
            let imChat = IMChatRegistry.shared.chat(for: bestHandle)
            imChat.forceToSMS()
            imChat.setRecipient(smsEmailHandle, locally: false)
            defer {
                IMChat.regressionTesting_disableServiceRefresh = false
            }
            if outcome == .succeed {
                IMChat.regressionTesting_disableServiceRefresh = false
            } else {
                IMChat.regressionTesting_disableServiceRefresh = true
            }
            let chat = Chat(imChat)
            do {
                let message = try chat.send(message: CreateMessage(parts: [.init(type: .text, details: "asdf")]))
                if outcome == .succeed {
                    guard message.service == .iMessage else {
                        preconditionFailure("Expected Barcelona Chat to retarget itself to iMessage when sending SMS to an email, but the message sent as \(message.service.rawValue).")
                    }
                } else {
                    guard message.service == .SMS else {
                        preconditionFailure("Expected Barcelona Chat to send SMS to an email, but the message sent as \(message.service.rawValue).")
                    }
                }
            } catch {
                preconditionFailure("Error while sending message: \(error)")
            }
        }
        
        func go(_ outcome: Outcome) {
            // hunt down the SMS email handle
            guard let smsEmailHandle = handles.first(where: {
                $0.id.isEmail && $0.service?.id == .SMS
            }) else {
                preconditionFailure("Expected to find an SMS email handle, but did not.")
            }
            guard let bestHandle = IMHandle.bestIMHandle(in: handles) else {
                preconditionFailure("Expected to find the best handle from a set of handles, but did not.")
            }
            let chat = IMChatRegistry.shared.chat(for: bestHandle)
            chat.forceToSMS()
            chat.setRecipient(smsEmailHandle, locally: false)
            if outcome == .succeed {
                guard chat.forceRefresh else {
                    preconditionFailure("SMS IMChat pointing to an email should have requested refresh, but it did not.")
                }
                chat.refreshServiceForSendingIfNeeded()
                guard chat.account.service?.id == .iMessage else {
                    preconditionFailure("SMS IMChat pointing to an email should have retargeted to iMessage, but it did not.")
                }
            } else {
                guard chat.account.service?.id == .SMS else {
                    preconditionFailure("SMS IMChat pointing to an email should be targeted to SMS, but it is not.")
                }
            }
            let message = IMMessage(sender: nil, time: nil, text: NSAttributedString(string: "asdf"), fileTransferGUIDs: nil, flags: 5, error: nil, guid: UUID().uuidString, subject: nil)!
            chat.send(message)
            let item = message._imMessageItem!
            if outcome == .succeed {
                guard item.serviceStyle == .iMessage else {
                    preconditionFailure("SMS IMChat pointing to an email should have retargeted to iMessage, but the message sent over \(item.service ?? "SMS")")
                }
            } else {
                guard item.serviceStyle == .SMS else {
                    preconditionFailure("SMS IMChat pointing to an email should have sent the message over SMS during repro, but the message sent over \(item.service ?? "iMessage")")
                }
            }
        }
        
        go(.fail)
        go(.succeed)
        go_barcelona(.fail)
        go_barcelona(.succeed)
    }
}
