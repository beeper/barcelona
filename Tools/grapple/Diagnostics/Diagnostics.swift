//
//  File.swift
//  grapple
//
//  Created by Eric Rabil on 12/14/21.
//

import Barcelona
import BarcelonaMautrixIPC
import Foundation
import IMCore
import SwiftCLI

struct ChatDiagnostics: Codable {
    static func diagnostics(forChat id: String, recentMessagesCount: Int) async throws -> ChatDiagnostics? {
        guard let chat = await Chat.firstChatRegardlessOfService(withId: id) else {
            return nil
        }

        let messages = try await chat.messages(before: nil, limit: 50, beforeDate: nil)
        let handles = chat.participants.map(Handle.init(id:))

        return ChatDiagnostics(
            chat: chat,
            blChat: chat.imChat!.blChat,
            myHandle: chat.imChat!.lastAddressedHandleID,
            participants: chat.participants.map(Handle.init(id:)),
            recentBLMessages: messages.map(BLMessage.init(message:)),
            recentMessages: messages
        )
    }

    var chat: Chat
    var blChat: BLChat

    var myHandle: String
    var participants: [Handle]

    var recentBLMessages: [BLMessage]
    var recentMessages: [Message]
}

struct AccountDiagnostics: Codable {
    init(account: IMAccount) {
        activeAliases = account.aliases
        // Ignore the Xcode warning, I think we're just not confident it'll actually return an array of strings
        allAliases = account.vettedAliases
        serviceID = account.serviceName
        registered = account.isRegistered
        active = account.isActive
        connected = account.isConnected
        connecting = account.isConnecting
        id = account.uniqueID
        registrationStatus = account.registrationStatus.rawValue
        registrationFailureReason = account.registrationFailureReason.rawValue
    }

    var activeAliases: [String]
    var allAliases: [String]
    var serviceID: String
    var registered: Bool
    var active: Bool
    var connected: Bool
    var connecting: Bool
    var id: String?
    var registrationStatus: Int
    var registrationFailureReason: Int
}

extension Encodable {
    var prettyJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        return try! String(decoding: encoder.encode(encode(to:)), as: UTF8.self)
    }
}

enum ResolveResult<ResolvedValue> {
    case found(ResolvedValue)
    case notFound(String)
}

protocol DiagResolver {
    associatedtype ResolvedValue
    static func resolve(_ id: String) -> ResolveResult<ResolvedValue>
}

extension IMServiceStyle: DiagResolver {
    static func resolve(_ serviceID: String) -> ResolveResult<IMServiceImpl> {
        guard let serviceStyle = IMServiceStyle(rawValue: serviceID) else {
            return .notFound(
                (["Unknown service. Valid services:"] + IMServiceStyle.allCases.map(\.rawValue)).joined(separator: "\n")
            )
        }

        return .found(serviceStyle.service)
    }
}

extension IMAccount {
    var serviceTag: String {
        "\(service!.id!.rawValue)/\(login!)"
    }
}

class DiagsCommand: CommandGroup {
    let name = "diags"
    let shortDescription = "do diagnostics on different imessage components"

    class ConfCommand: BarcelonaCommand {
        let name = "conf"

        struct ConfPath {
            static func some(_ path: String, callback: @escaping (String) -> Promise<String>) -> ConfPath {
                ConfPath(path: path, callback: .argument(callback))
            }
            static func some(_ path: String, callback: @escaping (String) -> Promise<Void>) -> ConfPath {
                ConfPath(path: path, callback: .argumentVoid(callback))
            }
            static func some(_ path: String, callback: @escaping (String) -> String) -> ConfPath {
                ConfPath(path: path, callback: .syncArgument(callback))
            }
            static func some(_ path: String, callback: @escaping (String) -> Void) -> ConfPath {
                ConfPath(path: path, callback: .syncArgumentVoid(callback))
            }
            static func some(_ path: String, callback: @escaping () -> Promise<String>) -> ConfPath {
                ConfPath(path: path, callback: .direct(callback))
            }
            static func some(_ path: String, callback: @escaping () -> Promise<Void>) -> ConfPath {
                ConfPath(path: path, callback: .directVoid(callback))
            }
            static func some(_ path: String, callback: @escaping () -> String) -> ConfPath {
                ConfPath(path: path, callback: .syncDirect(callback))
            }
            static func some(_ path: String, callback: @escaping () -> Void) -> ConfPath {
                ConfPath(path: path, callback: .syncDirectVoid(callback))
            }

            enum Invocation {
                case argument((String) -> Promise<String>)
                case argumentVoid((String) -> Promise<Void>)

                case syncArgument((String) -> String)
                case syncArgumentVoid((String) -> Void)

                case direct(() -> Promise<String>)
                case directVoid(() -> Promise<Void>)

                case syncDirect(() -> String)
                case syncDirectVoid(() -> Void)

                var hasArgument: Bool {
                    switch self {
                    case .argument, .argumentVoid, .syncArgument, .syncArgumentVoid:
                        return true
                    default:
                        return false
                    }
                }

                func callAsFunction(argument: String) -> Promise<String> {
                    switch self {
                    case .argument(let callback): return callback(argument)
                    case .argumentVoid(let callback): return callback(argument).replace(with: "")
                    case .syncArgument(let callback): return .success(callback(argument))
                    case .syncArgumentVoid(let callback):
                        callback(argument)
                        return .success("")
                    default:
                        return self(void: ())
                    }
                }

                func callAsFunction(void: ()) -> Promise<String> {
                    switch self {
                    case .direct(let callback): return callback()
                    case .directVoid(let callback): return callback().replace(with: "")
                    case .syncDirect(let callback): return .success(callback())
                    case .syncDirectVoid(let callback):
                        callback()
                        return .success("")
                    default:
                        fatalError("Attempt to call invocation with zero arguments when one is required.")
                    }
                }

                func callAsFunction(_ arg: String?) -> Promise<String> {
                    if hasArgument {
                        guard let arg = arg, !arg.isEmpty else {
                            return .success("Missing required argument")
                        }

                        return self(argument: arg)
                    } else {
                        return self(void: ())
                    }
                }
            }

            var path: String
            var callback: Invocation
        }

        static func serviceCommand(callback: @escaping (IMServiceImpl) -> String) -> (String) -> String {
            return { serviceID in
                guard case .found(let service) = IMServiceStyle.resolve(serviceID) else {
                    return (["Unknown service. Valid services:"] + IMServiceStyle.allCases.map(\.rawValue))
                        .joined(separator: "\n")
                }

                return callback(service)
            }
        }

        static let paths: [ConfPath] = [
            .some(
                "service.deactivate",
                callback: serviceCommand { service in
                    for account in IMAccountController.shared.accounts(for: service) {
                        guard account.isRegistered else {
                            print("skip \(account.serviceTag): not registered")
                            continue
                        }

                        print("deactivate: \(account.serviceTag)")
                        guard account.unregisterAccount() else {
                            return "deactivate failed for \(service.name!)/\(account.login!)"
                        }
                    }

                    return "ok"
                }
            ),
            .some(
                "service.activate",
                callback: serviceCommand { service in
                    for account in IMAccountController.shared.accounts(for: service) {
                        guard !account.isRegistered else {
                            print("skip \(account.serviceTag): already registered")
                            continue
                        }

                        print("activate: \(account.serviceTag)")
                        guard account.register() else {
                            return "activate failed for \(account.serviceTag)"
                        }
                    }

                    return "ok"
                }
            ),
            .some("alias.enable") { tag -> String in
                let components = tag.split(separator: "/")

                guard components.count == 2 else {
                    return "invalid service tag"
                }

                guard let service = IMServiceStyle(rawValue: String(components[0]))?.service else {
                    return "invalid service tag"
                }

                let alias = String(components[1])

                for account in IMAccountController.shared.accounts(for: service) {
                    guard account.vettedAliases.contains(alias) else {
                        print("skip \(account.serviceTag): alias not vetted")
                        continue
                    }

                    print("\(account.serviceTag): enable \(alias)")
                    guard account.addAlias(alias) else {
                        return "\(account.serviceTag): could not enable \(alias)"
                    }
                }

                return "ok"
            },
            .some("alias.disable") { tag -> String in
                let components = tag.split(separator: "/")

                guard components.count == 2 else {
                    return "invalid service tag"
                }

                guard let service = IMServiceStyle(rawValue: String(components[0]))?.service else {
                    return "invalid service tag"
                }

                let alias = String(components[1])

                for account in IMAccountController.shared.accounts(for: service) {
                    guard account.vettedAliases.contains(alias) else {
                        print("skip \(account.serviceTag): alias not vetted")
                        continue
                    }

                    print("\(account.serviceTag): disable \(alias)")
                    guard account.removeAlias(alias) else {
                        return "\(account.serviceTag): could not disable \(alias)"
                    }
                }

                return "ok"
            },
            .some("help") { () -> Void in
                for (path, invocation) in pathsByPath {
                    if invocation.hasArgument {
                        print(path + " <arg>")
                    } else {
                        print(path)
                    }
                }
            },
        ]
        static let pathsByPath: [String: ConfPath.Invocation] = paths.dictionary(keyedBy: \.path, valuedBy: \.callback)

        @Param var path: String
        @Param var argument: String?

        func execute() throws {
            guard let pathCallback = Self.pathsByPath[path] else {
                print("Unknown path '\(path)'")
                exit(0)
            }

            pathCallback(argument)
                .then {
                    if !$0.isEmpty {
                        print($0)
                    }

                    exit(0)
                }
        }
    }

    class AccountsCommand: BarcelonaCommand {
        let name = "accounts"

        func execute() throws {
            print(IMAccountController.shared.accounts.map(AccountDiagnostics.init(account:)).prettyJSON)
            exit(0)
        }
    }

    class MessagesCommand: BarcelonaCommand {
        let name = "messages"

        @Param var chatID: String?

        func execute() throws {
            CBDaemonListener.shared.messagePipeline.pipe { message in
                if let chatID = self.chatID {
                    guard message.chatID == chatID else {
                        return
                    }
                }

                print(message.prettyJSON)
            }
        }
    }

    class ChatListCommand: BarcelonaCommand {
        let name = "chatlist"

        @Key("--login") var loginHandleFilter: String?

        func execute() throws {
            _Concurrency.Task {
                var chats = await Chat.allChats

                if let loginHandleFilter = loginHandleFilter {
                    chats = chats.filter {
                        $0.imChat?.lastAddressedHandleID == loginHandleFilter
                    }
                }

                print(chats.dictionary(keyedBy: \.id, valuedBy: \.participants).prettyJSON)
                exit(0)
            }
        }
    }

    class ChatDiagsCommand: BarcelonaCommand {
        let name = "chat"

        @Param var id: String

        @Key("-l") var limit: Int?

        func execute() throws {
            _Concurrency.Task {
                guard let diagnostics = try? await ChatDiagnostics.diagnostics(forChat: id, recentMessagesCount: limit ?? 25) else {
                    return print(["error": "no chat with that ID", "id": self.id].prettyJSON)
                }

                print(diagnostics.prettyJSON)
                exit(0)
            }
        }
    }

    var children: [Routable] = [
        ChatDiagsCommand(), ChatListCommand(), MessagesCommand(), AccountsCommand(), ConfCommand(),
    ]
}
