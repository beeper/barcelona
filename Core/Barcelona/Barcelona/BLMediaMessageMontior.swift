//
//  BLMediaMessageMontior.swift
//  Barcelona
//
//  Created by Eric Rabil on 4/30/22.
//

import Foundation
import IMCore
import Combine
import Swog
@_spi(synchronousQueries) import BarcelonaDB

fileprivate let log = Logger(category: "MessageMonitor")

public class BLMediaMessageMonitor {
    public let messageID: () -> String
    public let transferGUIDs: [String]
    
    private var monitor: BLMessageExpert.BLMessageObserver?
    @Published public private(set) var latestMessageEvent: BLMessageExpert.BLMessageEvent?
    @Published public private(set) var transferStates: [String: IMFileTransfer.IMFileTransferState]
    private var completionMonitor: AnyCancellable?
    private var observer: NotificationSubscription?
    private let callback: (Bool, FZErrorType?) -> ()
    
    public init(messageID: @autoclosure @escaping () -> String, transferGUIDs: [String], callback: @escaping (Bool, FZErrorType?) -> ()) {
        self.messageID = messageID
        self.transferGUIDs = transferGUIDs
        self.callback = callback
        self.transferStates = transferGUIDs.map { ($0, IMFileTransfer.IMFileTransferState.unknown) }.dictionary(keyedBy: \.0, valuedBy: \.1)
        var monitor: BLMessageExpert.BLMessageObserver?
        log.debug("Set up monitoring for message %@ and transfers %@", messageID(), transferGUIDs)
        monitor = BLMessageExpert.shared.observer(forMessage: messageID()) { [weak self, messageID, monitor] event in
            guard let self = self else {
                log.info("Destroying message observer for dealloc'd monitor of %@", messageID())
                monitor?.cancel()
                return
            }
            if case .message = event {
                log.debug("Ignoring message event for %@, I want lifecycle only", messageID())
                return
            }
            log.debug("Processing message event %@ for message %@", event.name.rawValue, messageID())
            self.latestMessageEvent = event
        }
        self.monitor = monitor
        if !transferGUIDs.isEmpty {
            observer = NotificationCenter.default.subscribe(toNotificationsNamed: [.IMFileTransferUpdated, .IMFileTransferFinished]) { [weak self] notification, subscription in
                guard let self = self else {
                    return subscription.unsubscribe()
                }
                self.handle(transferNotification: notification, subscription: subscription)
            }
        }
        completionMonitor = Publishers.CombineLatest(
            $latestMessageEvent.removeDuplicates(),
            $transferStates.removeDuplicates()
        ).sink { [weak self] latestEvent, latestStates in
            guard let self = self else {
                return
            }
            self.handle(updatedEvent: latestEvent, updatedStates: latestStates)
        }
    }
    
    deinit {
        monitor?.cancel()
        observer?.unsubscribe()
        log.debug("Deallocating message monitor for message %@ and transfers %@", messageID(), transferGUIDs)
    }
    
    public private(set) var result: (Bool, FZErrorType?)?
    
    private func snap(success: Bool, code: FZErrorType?) {
        guard result == nil else {
            return
        }
        completionMonitor = nil
        result = (success, code)
        self.callback(success, code)
    }
    
    private func handle(updatedEvent latestEvent: BLMessageExpert.BLMessageEvent?, updatedStates latestStates: [String: IMFileTransfer.IMFileTransferState]) {
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
            debugMessageState()
        }
        switch latestEvent {
        case .sent, .read, .delivered:
            if finishedCount == transferGUIDs.count {
                snap(success: true, code: nil)
            }
        case .failed(_, _, let code):
            snap(success: false, code: code)
        case .sending:
            return
        default:
            return
        }
    }
    
    private func handle(transferNotification notification: Notification, subscription: NotificationSubscription) {
        guard let transfer = notification.object as? IMFileTransfer else {
            return
        }
        guard transferGUIDs.contains(transfer.guid) else {
            return
        }
        log.info("Processing transfer state %@ for transfer %@ for message %@", transfer.state.description, transfer.guid, messageID())
        transferStates[transfer.guid] = transfer.state
    }
    
    private func debugMessageState() {
        let messageID = messageID()
        if messageID.isEmpty {
            log.debug("A BLMediaMessageMonitor has no message ID at time of inspection")
            return
        }
        guard let message = BLLoadIMMessage(withGUID: messageID) else {
            log.debug("A BLMediaMessageMonitor was given a message ID that does not exist")
            return
        }
        log.debug("%@; errorCode=%@", message.debugDescription, message.errorCode.description)
    }
}
