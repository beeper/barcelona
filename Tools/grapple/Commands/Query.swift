//
//  Query.swift
//  grapple-macOS
//
//  Created by Eric Rabil on 8/5/22.
//

import Barcelona
import Foundation
import IMCore
import SwiftCLI

class QueryCommand: EphemeralBarcelonaCommand {
    let name = "query"

    @Param var path: String

    @CollectedParam var subpath: [String]

    enum BasePath: String {
        case iMessageAccount = "account.imessage"
        case smsAccount = "account.sms"
        case accounts
        case handles
        case chats

        func eat(subpath: String) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            func send(_ value: NSObject) {
                if subpath.count == 0 {
                    return print(String(decoding: try! encoder.encode(value), as: UTF8.self))
                }

                if let encodable = value.value(forKeyPath: subpath) as? Encodable {
                    print(String(decoding: try! encoder.encode(EncodingBox(encodable: encodable)), as: UTF8.self))
                } else {
                    print("Unknown keypath \(subpath)")
                }
            }

            switch self {
            case .iMessageAccount:
                send(IMAccountController.shared.iMessageAccount!)
            case .smsAccount:
                if let account = IMAccountController.shared.activeSMSAccount {
                    send(account)
                } else {
                    print("No SMS account found")
                }
            case .accounts:
                send(IMAccountController.shared.accounts as NSArray)
            case .handles:
                send(
                    IMHandleRegistrar.sharedInstance().allIMHandles()!.collectedDictionary(keyedBy: \.id)
                        as NSDictionary
                )
            case .chats:
                send(IMChatRegistry.shared.allChats.collectedDictionary(keyedBy: \.chatIdentifier) as NSDictionary)
            }

            visited = Set()
        }
    }

    func execute() throws {
        BasePath(rawValue: path)?.eat(subpath: subpath.joined(separator: "."))
    }
}
