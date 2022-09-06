import BarcelonaMautrixIPCProtobuf
import NIO
import Barcelona
import IMCore
import GRPC

extension EventLoop {
    func wrap<P>(_ promise: Promise<P>) -> EventLoopFuture<P> {
        let niopromise = makePromise(of: P.self)
        
        promise.always {
            switch $0 {
            case .success(let output): niopromise.succeed(output)
            case .failure(let error): niopromise.fail(error)
            }
        }
        
        return niopromise.futureResult
    }
}

class BarcelonaRPC: BarcelonaProvider {
    var interceptors: BarcelonaServerInterceptorFactoryProtocol?

    func requestHistory(request: PBHistoryQuery, context: StatusOnlyCallContext) -> EventLoopFuture<PBMessageList> {
        guard let chat = request.chatGuid.cbChat else {
            return context.eventLoop.makeSucceededFuture(.with {
                $0.error = "unknown chat"
            })
        }
        let identifiers = chat.chatIdentifiers
        
        let itemsFuture = context.eventLoop.wrap(BLLoadChatItems(
            withChatIdentifiers: identifiers,
            onServices: .CBMessageServices,
            afterDate: request.hasAfterDate ? request.afterDate.date : nil,
            beforeDate: request.hasBeforeDate ? request.beforeDate.date : nil,
            afterGUID: request.hasAfterGuid ? request.afterGuid : nil,
            beforeGUID: request.hasBeforeGuid ? request.beforeGuid : nil
        ))
        let flatFuture = itemsFuture.map { items -> [PBMessage] in
            items.compactMap { item -> PBMessage? in
                switch item {
                case let message as Message:
                    return .init(message: message)
                default:
                    guard let pb = PBItem(chatItem: item) else {
                        return nil
                    }
                    return .with { message in
                        message.guid = item.id
                        message.chatGuid = .with {
                            $0.localID = item.chatID
                            $0.service = "iMessage"
                            $0.isGroup = IMChatRegistry.shared.existingChat(withChatIdentifier: item.chatID)?.isGroup ?? false
                        }
                        message.items = [pb]
                    }
                }
            }
        } as EventLoopFuture<[PBMessage]>
        let listFuture = flatFuture.map { messages -> PBMessageList in
            PBMessageList.with { list in
                list.messages = messages
            }
        }
        return listFuture
    }

    func asdf() {
        
    }
}
