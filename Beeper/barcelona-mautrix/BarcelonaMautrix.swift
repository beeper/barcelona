//
//  BarcelonaMautrix.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import BarcelonaMautrixIPC
import Combine
import Foundation
import IMCore
import Logging
import Sentry

private let log = Logger(label: "BarcelonaMautrix")

class BarcelonaMautrix {
    private let mautrixIPCChannel: MautrixIPCChannel
    private let reader: BLPayloadReader
    private let eventHandler: BLEventHandler
    private let chatRegistry: CBChatRegistry

    private var cancellables = Set<AnyCancellable>()

    init(_ mautrixIPCChannel: MautrixIPCChannel) {
        self.mautrixIPCChannel = mautrixIPCChannel
        let chatRegistry = CBChatRegistry()
        reader = BLPayloadReader(ipcChannel: mautrixIPCChannel, chatRegistry: chatRegistry)
        eventHandler = BLEventHandler(ipcChannel: mautrixIPCChannel)
        self.chatRegistry = chatRegistry
    }

    static func getUnixSocketPath() -> String? {
        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: "--unix-socket"),
            ProcessInfo.processInfo.arguments.count > index + 1
        else {
            return nil
        }
        return ProcessInfo.processInfo.arguments[index + 1]
    }
    
    static func run(_ unixSocketPath: String) {
        let unixMautrixIPCChannel = UnixSocketMautrixIPCChannel(unixSocketPath)
        let mautrixIPCChannel = MautrixIPCChannel(
            inputHandle: unixMautrixIPCChannel,
            outputHandle: unixMautrixIPCChannel
        )

        let barcelonaMautrix = BarcelonaMautrix(mautrixIPCChannel)

        Task {
            await barcelonaMautrix.bootstrap()
        }

        log.info("Starting the RunLoop")
        RunLoop.main.run()
    }

    func bootstrap() async {
        let startupSpan = SentrySDK.span
        let bootstrapSpan = startupSpan?.startChild(operation: "bootstrap")
        log.info("Bootstrapping")

        do {
            let success = try await BarcelonaManager.shared.bootstrap(chatRegistry: chatRegistry)

            guard success else {
                log.error("Failed to bootstrap")
                startupSpan?.finish(status: .internalError)
                bootstrapSpan?.finish(status: .internalError)
                exit(-1)
            }

            #if DEBUG
            await chatRegistry.onLoadedChats {
                await _scratchboxMain(chatRegistry: self.chatRegistry)
            }
            #endif

            // allow payloads to start flowing
            self.reader.ready = true
            BLHealthTicker.shared.pinnedBridgeState = nil

            CBPurgedAttachmentController.shared.enabled = true
            CBPurgedAttachmentController.shared.delegate = self.eventHandler

            // starts the imessage notification processor
            self.eventHandler.run()

            log.info("BLMautrix is ready")

            self.startHealthTicker()
            bootstrapSpan?.finish()
            startupSpan?.finish()
        } catch {
            log.error("fatal error while setting up barcelona: \(String(describing: error))")
            startupSpan?.finish(status: .internalError)
            bootstrapSpan?.finish(status: .internalError)
            exit(197)
        }
    }

    // starts the bridge state interval
    func startHealthTicker() {
        BLHealthTicker.shared.debouncedDeduplicatedBridgeRemoteState
            .sink { command in
                self.mautrixIPCChannel.writePayload(IPCPayload(command: .bridge_status(command)))
            }
            .store(in: &cancellables)

        log.info("Sending initial bridge remote state")
        BLHealthTicker.shared.run(schedulingNext: true)
    }
}
