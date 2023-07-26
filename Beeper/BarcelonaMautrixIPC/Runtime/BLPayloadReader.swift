//
//  BLPayloadReader.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Combine
import Foundation

public class BLPayloadReader {
    private let ipcChannel: MautrixIPCChannel
    private let chatRegistry: CBChatRegistry

    private var queue = [IPCPayload]()

    private var bag = Set<AnyCancellable>()

    public init(ipcChannel: MautrixIPCChannel, chatRegistry: CBChatRegistry) {
        self.ipcChannel = ipcChannel
        self.chatRegistry = chatRegistry

        ipcChannel.receivedPayloads
            .sink { [weak self] in
                guard let self else { return }

                if self.ready {
                    BLHandlePayload($0, ipcChannel: ipcChannel, chatRegistry: chatRegistry)
                } else {
                    self.queue.append($0)
                }
            }
            .store(in: &bag)

        Task {
            await chatRegistry.failedMessages
                .sink { messageInfo in
                    ipcChannel.writePayload(
                        IPCPayload(
                            command: .send_message_status(
                                .init(
                                    guid: messageInfo.guid,
                                    chatGUID: messageInfo.chatGUID,
                                    status: .failed,
                                    service: messageInfo.service,
                                    message: messageInfo.error.localizedDescription,
                                    statusCode: (messageInfo.error as? CustomNSError)?.errorUserInfo[NSDebugDescriptionErrorKey] as? String
                                )
                            )
                        )
                    )
                }
                .store(in: &bag)
        }

        if ProcessInfo.processInfo.arguments.contains("-d") {
            self.ready = true
        }
    }

    public var ready = false {
        didSet {
            let queue = queue

            queue.forEach { BLHandlePayload($0, ipcChannel: ipcChannel, chatRegistry: chatRegistry) }
        }
    }
}
