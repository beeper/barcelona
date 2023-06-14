//
//  BLMediaMessageMontior.swift
//  Barcelona
//
//  Created by Eric Rabil on 4/30/22.
//

import BarcelonaDB
import Combine
import Foundation
import IMCore
import IMFoundation
import Logging

private let log = Logger(label: "MessageMonitor")

public class BLMediaMessageMonitor {
    public let messageID: () -> String
    public let transferGUIDs: [String]

    private var monitor: BLMessageExpert.BLMessageObserver?
    @Published public private(set) var latestMessageEvent: BLMessageExpert.BLMessageEvent?
    @Published public private(set) var transferStates: [String: IMFileTransfer.IMFileTransferState]
    private var completionMonitor: AnyCancellable?
    private var observer: NotificationSubscription?
    private var timeout: DispatchSourceTimer?
    private let callback: (Bool, FZErrorType?, Bool) -> Void

    public init(
        messageID: @autoclosure @escaping () -> String,
        transferGUIDs: [String],
        callback: @escaping (Bool, FZErrorType?, Bool) -> Void
    ) {
        self.messageID = messageID
        self.transferGUIDs = transferGUIDs
        self.callback = callback
        self.transferStates = transferGUIDs.map { ($0, IMFileTransfer.IMFileTransferState.unknown) }
            .dictionary(keyedBy: \.0, valuedBy: \.1)
        var monitor: BLMessageExpert.BLMessageObserver?
        log.debug("Set up monitoring for message \(messageID()) and transfers \(transferGUIDs)")
        monitor = BLMessageExpert.shared.observer(forMessage: messageID()) { [weak self, messageID, monitor] event in
            guard let self = self else {
                log.info("Destroying message observer for dealloc'd monitor of \(messageID())")
                monitor?.cancel()
                return
            }
            if case .message = event {
                log.debug("Ignoring message event for \(messageID()), I want lifecycle only")
                return
            }
            log.debug("Processing message event \(event.name.rawValue) for message \(messageID())")
            self.latestMessageEvent = event
        }
        self.monitor = monitor
        if !transferGUIDs.isEmpty {
            observer = NotificationCenter.default.subscribe(toNotificationsNamed: [
                .IMFileTransferUpdated, .IMFileTransferFinished,
            ]) { [weak self] notification, subscription in
                guard let self = self else {
                    return subscription.unsubscribe()
                }
                self.handle(transferNotification: notification, subscription: subscription)
            }
        }
        completionMonitor =
            Publishers.CombineLatest(
                $latestMessageEvent.removeDuplicates(),
                $transferStates.removeDuplicates()
            )
            .sink { [weak self] latestEvent, latestStates in
                guard let self = self else {
                    return
                }
                self.handle(updatedEvent: latestEvent, updatedStates: latestStates)
            }
        startTimer()
    }

    deinit {
        monitor?.cancel()
        observer?.unsubscribe()
        timeout?.cancel()
        log.debug("Deallocating message monitor for message \(messageID()) and transfers \(transferGUIDs)")
    }

    public private(set) var result: (Bool, FZErrorType?, Bool)?

    private func snap(success: Bool, code: FZErrorType?, shouldCancel: Bool = false) {
        guard result == nil else {
            return
        }
        timeout?.cancel()
        completionMonitor = nil
        result = (success, code, shouldCancel)
        self.callback(success, code, shouldCancel)
    }

    private func handle(
        updatedEvent latestEvent: BLMessageExpert.BLMessageEvent?,
        updatedStates latestStates: [String: IMFileTransfer.IMFileTransferState]
    ) {
        var finishedCount = 0
        for state in latestStates.values {
            switch state {
            case .error, .recoverableError:
                return snap(success: false, code: .attachmentUploadFailure)
            case .finished:
                finishedCount += 1
            default:
                continue
            }
        }
        if finishedCount == transferGUIDs.count {
            log.debug("All transfers have finished! Removing the transfer observer.")
            observer?.unsubscribe()
            observer = nil
            let messageID = messageID()
            if messageID.isEmpty {
                log.debug("A BLMediaMessageMonitor has no message ID at time of inspection")
                return
            }
            guard let message = BLLoadIMMessage(withGUID: messageID) else {
                log.debug("A BLMediaMessageMonitor was given a message ID that does not exist")
                return
            }
            #if DEBUG
            log.debug("\(message.debugDescription); errorCode=\(message.errorCode.description)")
            #endif
            if message.isSent && message.isFinished {
                if message._imMessageItem.service?.service?.id == .SMS {
                    return snap(success: true, code: nil)
                }
            }
        }
        switch latestEvent {
        case .sent, .read, .delivered:
            if finishedCount == transferGUIDs.count {
                snap(success: true, code: nil)
            }
        case .failed(_, _, _, let code):
            snap(success: false, code: code)
        case .sending:
            return
        default:
            return
        }
    }

    private func handle(transferNotification notification: Notification, subscription _: NotificationSubscription) {
        guard let transfer = notification.decodeObject(to: IMFileTransfer.self) else {
            return
        }
        guard let guid = transfer.guid, transferGUIDs.contains(guid) else {
            return
        }
        log.info(
            "Processing transfer state \(transfer.state.description) for transfer \(guid) for message \(messageID())"
        )
        transferStates[guid] = transfer.state
    }
}

extension BLMediaMessageMonitor {
    fileprivate func startTimer() {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: .global(qos: .userInitiated))
        timer.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }
            let messageID = self.messageID()
            log.warning(
                "Failed to send message \(messageID) with attachments \(self.transferGUIDs) in a timely manner! This is very, very sad."
            )
            self.snap(success: false, code: .attachmentUploadFailure, shouldCancel: true)
        }
        timer.schedule(deadline: .now().advanced(by: .seconds(60)))
        timer.resume()
        timeout = timer
    }
}
