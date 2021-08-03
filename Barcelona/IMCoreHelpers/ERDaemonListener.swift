//
//  ERDaemonListener.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import os.log

/**
 Interfaces with imagent, methods called here are called by the daemon.
 */
public class ERDaemonListener: IMDaemonListenerProtocol {
    public static let shared = ERDaemonListener()
    
    private init() {
        
    }
    
    @objc public func lastMessage(forAllChats arg1: [AnyHashable : Any]!) {
        
    }
    
    @objc public func screenTimeEnablementChanged(_ arg1: Bool) {
        
    }
    
    @objc public func didFetchCloudKitSyncDebuggingInfo(_ arg1: [AnyHashable : Any]!) {
        
    }
    
    @objc public func receivedUrgentRequest(forMessages arg1: [Any]!) {
        
    }
    
    @objc public func oneTimeCodesDidChange(_ arg1: [Any]!) {
        
    }
    
    @objc public func didAttempt(toDisableiCloudBackups arg1: Int64, error arg2: Error!) {
        
    }
    
    @objc public func didFetchRampState(_ arg1: [AnyHashable : Any]!) {
        
    }
    
    @objc public func didFetchSyncStateStats(_ arg1: [AnyHashable : Any]!) {
        
    }
    
    @objc public func didAttempt(toDisableAllDevicesResult arg1: Bool) {
        
    }
    
    @objc public func didPerformAdditionalStorageRequiredCheck(withSuccess arg1: Bool, additionalStorageRequired arg2: UInt64, forAccountId arg3: String!, error arg4: Error!) {
        
    }
    
    @objc public func didAttemptToSetEnabled(to arg1: Bool, result arg2: Bool) {
        
    }
    
    @objc public func updateCloudKitState(with arg1: [AnyHashable : Any]!) {
        
    }
    
    @objc public func updateCloudKitState() {
        
    }
    
    @objc public func updatePersonalNickname(_ arg1: IMNickname!) {
        
    }
    
    @objc public func pendingNicknamesOrHandledNicknamesDidChange() {
        
    }
    
    @objc public func handlesSharingNicknamesDidChange() {
        
    }
    
    @objc public func updateNicknameHandlesSharing(_ arg1: Set<AnyHashable>!, handlesBlocked arg2: Set<AnyHashable>!) {
        
    }
    
    @objc public func updatePendingNicknameUpdates(_ arg1: [AnyHashable : Any]!, handledNicknameUpdates arg2: [AnyHashable : Any]!) {
        
    }
    
    @objc public func updateNicknameData(_ arg1: Data!) {
        
    }
    
    @objc public func nicknameRequestResponse(_ arg1: String!, encodedNicknameData arg2: Data!) {
        
    }
    
    @objc public func qosClassWhileServicingRequestsResponse(_ arg1: UInt32, identifier arg2: String!) {
        
    }
    
    @objc public func stickerPackRemoved(_ arg1: [Any]!) {
        
    }
    
    @objc public func stickerPackUpdated(_ arg1: [AnyHashable : Any]!) {
        
    }
    
    @objc public func pinCodeAlertCompleted(_ arg1: String!, deviceName arg2: String!, deviceType arg3: String!, phoneNumber arg4: String!, responseFromDevice arg5: Bool, wasCancelled arg6: Bool) {
        
    }
    
    @objc public func displayPinCode(forAccount arg1: String!, pinCode arg2: NSNumber!, deviceName arg3: String!, deviceType arg4: String!, phoneNumber arg5: String!) {
        
    }
    
    @objc public func lastFailedMessageDateChanged(_ arg1: Int64) {
        
    }
    
    @objc public func unreadCountChanged(_ arg1: Int64) {
        
    }
    
    @objc public func databaseChatSpamUpdated(_ arg1: String!) {
        
    }
    
    @objc public func databaseUpdated(_ arg1: String!) {
        
    }
    
    @objc public func databaseUpdated() {
        
    }
    
    @objc public func account(_ arg1: String!, relay arg2: String!, handleCancel arg3: [AnyHashable : Any]!, fromPerson arg4: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, relay arg2: String!, handleUpdate arg3: [AnyHashable : Any]!, fromPerson arg4: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, relay arg2: String!, handleInitate arg3: [AnyHashable : Any]!, fromPerson arg4: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, postedError arg2: Error!) {
        
    }
    
    @objc public func account(_ arg1: String!, statusChanged arg2: [AnyHashable : Any]!) {
        
    }
    
    @objc public func persistentProperty(_ arg1: String!, changedTo arg2: Any!, from arg3: Any!) {
        
    }
    
    @objc public func property(_ arg1: String!, changedTo arg2: Any!, from arg3: Any!) {
        
    }
    
    @objc public func showForgotPasswordNotification(forAccount arg1: String!) {
        
    }
    
    @objc public func showInvalidCertNotification(forAccount arg1: String!) {
        
    }
    
    @objc public func account(_ arg1: String!, avAction arg2: UInt32, withArguments arg3: [AnyHashable : Any]!, toAVChat arg4: String!, isVideo arg5: Bool) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, invitationSentSuccessfully arg3: Bool) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, peerID arg3: String!, propertiesUpdated arg4: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, peerIDChangedFromID arg3: String!, toID arg4: String!) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, changedToNewConferenceID arg3: String!) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, receivedAVMessage arg3: UInt32, from arg4: [AnyHashable : Any]!, sessionID arg5: UInt32, userInfo arg6: [AnyHashable : Any]! = [:]) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, receivedUpdateFrom arg3: [AnyHashable : Any]!, data arg4: Data!) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, receivedCounterProposalFrom arg3: [AnyHashable : Any]!, properties arg4: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, receivedCancelInvitationFrom arg3: [AnyHashable : Any]!, properties arg4: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, receivedResponseToInvitationFrom arg3: [AnyHashable : Any]!, properties arg4: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, conference arg2: String!, receivedInvitationFrom arg3: [AnyHashable : Any]!, properties arg4: [AnyHashable : Any]!) {
        
    }
    
    @objc public func fileTransferHighQualityDownloadFailed(_ arg1: String!) {
        
    }
    
    @objc public func fileTransfer(_ arg1: String!, highQualityDownloadSucceededWithPath arg2: String!) {
        
    }
    
    @objc public func fileTransfer(_ arg1: String!, updatedWithCurrentBytes arg2: UInt64, totalBytes arg3: UInt64, averageTransferRate arg4: UInt64) {
        
    }
    
    @objc public func fileTransfers(_ arg1: [Any]!, createdWithLocalPaths arg2: [Any]!) {
        
    }
    
    @objc public func fileTransfer(_ arg1: String!, updatedWithProperties arg2: [AnyHashable : Any]!) {
        
    }
    
    @objc public func fileTransfer(_ arg1: String!, createdWithProperties arg2: [AnyHashable : Any]!) {
        
    }
    
    @objc public func blackholedChatsExist(_ arg1: Bool) {
        
    }
    
    @objc public func previouslyBlackholedChatLoaded(withHandleIDs arg1: [Any]!, chat arg2: [AnyHashable : Any]!) {
        
    }
    
    @objc public func chatLoaded(withChatIdentifier arg1: String!, chats arg2: [Any]!) {
        
    }
    
    @objc public func frequentRepliesQuery(_ arg1: String!, chatID arg2: String!, services arg3: [Any]!, finishedWithResult arg4: [Any]!, limit arg5: UInt64) {
        
    }
    
    @objc public func historicalMessageGUIDsDeleted(_ arg1: [Any]!, chatGUIDs arg2: [Any]!, queryID arg3: String!) {
        NotificationCenter.default.post(name: ERChatMessagesDeletedNotification, object: [
            "guids": arg1
        ])
    }
    
    @objc public func mark(asSpamQuery arg1: String!, chatID arg2: String!, services arg3: [Any]!, finishedWithResult arg4: NSNumber!) {
        
    }
    
    @objc public func finishedDownloadingPurgedAssets(forChatIDs arg1: [Any]!) {
        
    }
    
    @objc public func downloadedPurgedAssetBatch(forChatIDs arg1: [Any]!, completedTransferGUIDs arg2: [Any]!) {
        
    }
    
    @objc public func isDownloadingQuery(_ arg1: String!, chatID arg2: String!, services arg3: [Any]!, finishedWithResult arg4: Bool) {
        
    }
    
    @objc public func uncachedAttachmentCountQuery(_ arg1: String!, chatID arg2: String!, services arg3: [Any]!, finishedWithResult arg4: NSNumber!) {
        
    }
    
    @objc public func attachmentQuery(_ arg1: String!, chatID arg2: String!, services arg3: [Any]!, finishedWithResult arg4: [Any]!) {
        
    }
    
    @objc public func pagedHistoryQuery(_ arg1: String!, chatID arg2: String!, services arg3: [Any]!, numberOfMessagesBefore arg4: UInt64, numberOfMessagesAfter arg5: UInt64, finishedWithResult arg6: [Any]!) {
        
    }
    
    @objc public func historyQuery(_ arg1: String!, chatID arg2: String!, services arg3: [Any]!, finishedWithResult arg4: [Any]!, limit arg5: UInt64) {
        
    }
    
    @objc public func messageQuery(_ arg1: String!, finishedWithResult arg2: IMMessageItem!, chatGUIDs arg3: [Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, chatPersonCentricID arg5: String!, member arg6: [AnyHashable : Any]!, statusChanged arg7: Int32) {
        
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, groupID arg5: String!, chatPersonCentricID arg6: String!, statusChanged arg7: Int32, handleInfo arg8: [Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, error arg5: Error!) {
         
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, messagesUpdated arg5: [Any]!) {
        guard let arg2 = arg2 else { return }
        NotificationCenter.default.post(name: ERChatMessagesUpdatedNotification, object: arg5, userInfo: [
            "chat": arg2
        ])
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, notifySentMessage arg5: IMMessageItem!, sendTime arg6: NSNumber!) {
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, messageUpdated arg5: IMItem!) {
        guard let arg2 = arg2 else { return }
        NotificationCenter.default.post(name: ERChatMessageUpdatedNotification, object: arg5, userInfo: [
            "chat": arg2
        ])
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, groupID arg5: String!, chatPersonCentricID arg6: String!, messagesReceived arg7: [Any]!, messagesComingFromStorage arg8: Bool) {
        guard let arg2 = arg2 else { return }
        NotificationCenter.default.post(name: ERChatMessagesReceivedNotification, object: arg7, userInfo: [
            "chat": arg2
        ])
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, groupID arg5: String!, chatPersonCentricID arg6: String!, messageReceived arg7: IMItem!) {
        guard let arg2 = arg2 else { return }
        NotificationCenter.default.post(name: ERChatMessageReceivedNotification, object: arg7, userInfo: [
            "chat": arg2
        ])
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, groupID arg5: String!, chatPersonCentricID arg6: String!, messageSent arg7: IMMessageItem!) {
        guard let arg2 = arg2 else { return }
        NotificationCenter.default.post(name: BLChatMessageSentNotification, object: arg7.guid, userInfo: [
            "chat": arg2,
            "item": arg7
        ])
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, updateProperties arg5: [AnyHashable : Any]!) {
    }
    
    @objc public func account(_ arg1: String!, chat arg2: String!, style arg3: UInt8, chatProperties arg4: [AnyHashable : Any]!, invitationReceived arg5: IMMessageItem!) {
        
    }
    
    @objc public func chatsNeedRemerging(_ arg1: [Any]!, groupedChats arg2: [Any]!) {
        
    }
    
    @objc public func loadedChats(_ arg1: [Any]!) {
        
    }
    
    @objc public func engroupParticipantsUpdated(forChat arg1: String!) {
        
    }
    
    @objc public func leftChat(_ arg1: String!) {
        
    }
    
    @objc public func chat(_ arg1: String!, nicknamesUpdated arg2: [AnyHashable : Any]!) {
        
    }
    
    @objc public func chat(_ arg1: String!, engramIDUpdated arg2: String!) {
        
    }
    
    @objc public func chat(_ arg1: String!, isFilteredUpdated arg2: Bool) {
        
    }
    
    @objc public func chat(_ arg1: String!, lastAddressedSIMIDUpdated arg2: String!) {
        
    }
    
    @objc public func chat(_ arg1: String!, lastAddressedHandleUpdated arg2: String!) {
        
    }
    
    @objc public func chat(_ arg1: String!, displayNameUpdated arg2: String!) {
        
    }
    
    @objc public func chat(_ arg1: String!, propertiesUpdated arg2: [AnyHashable : Any]!) {
        
    }
    
    @objc public func chat(_ arg1: String!, updated arg2: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, buddyInfo arg2: [AnyHashable : Any]!, commandDelivered arg3: NSNumber!, properties arg4: [AnyHashable : Any]!) {
    }
    
    @objc public func account(_ arg1: String!, buddyInfo arg2: [AnyHashable : Any]!, commandReceived arg3: NSNumber!, properties arg4: [AnyHashable : Any]!) {
    }
    
    @objc public func networkDataAvailabilityChanged(_ arg1: Bool) {
        
    }
    
    @objc public func account(_ arg1: String!, handleSubscriptionRequestFrom arg2: [AnyHashable : Any]!, withMessage arg3: String!) {
        
    }
    
    @objc public func account(_ arg1: String!, buddyProperties arg2: [AnyHashable : Any]!, buddyPictures arg3: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, groupsChanged arg2: [Any]!, error arg3: Error!) {
        
    }
    
    @objc public func account(_ arg1: String!, buddyPictureChanged arg2: String!, imageData arg3: Data!, imageHash arg4: String!) {
        
    }
    
    @objc public func account(_ arg1: String!, blockIdleStatusChanged arg2: Bool) {
        
    }
    
    @objc public func account(_ arg1: String!, blockingModeChanged arg2: UInt32) {
        
    }
    
    @objc public func account(_ arg1: String!, allowListChanged arg2: [Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, blockListChanged arg2: [Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, buddyPropertiesChanged arg2: [Any]!) {
        
    }
    
    @objc public func accountRemoved(_ arg1: String!) {
        
    }
    
    @objc public func accountAdded(_ arg1: String!, defaults arg2: [AnyHashable : Any]!, service arg3: String!) {
        
    }
    
    @objc public func account(_ arg1: String!, capabilitiesChanged arg2: UInt64) {
        
    }
    
    @objc public func account(_ arg1: String!, defaultsChanged arg2: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, loginStatusChanged arg2: UInt32, message arg3: String!, reason arg4: Int32, properties arg5: [AnyHashable : Any]!) {
        
    }
    
    @objc public func account(_ arg1: String!, defaults arg2: [AnyHashable : Any]!, blockList arg3: [Any]!, allowList arg4: [Any]!, blockingMode arg5: UInt32, blockIdleStatus arg6: Bool, status arg7: [AnyHashable : Any]!, capabilities arg8: UInt64, serviceLoginStatus arg9: UInt32, loginStatusMessage arg10: String!) {
        
    }
    
    @objc public func activeAccountsChanged(_ arg1: [Any]!, forService arg2: String!) {
        
    }
    
    @objc public func defaultsChanged(_ arg1: [AnyHashable : Any]!, forService arg2: String!) {
        
    }
    
    @objc public func vcCapabilitiesChanged(_ arg1: UInt64) {
        
    }
    
    @objc public func pendingACRequestComplete() {
        
    }
    
    @objc public func pendingVCRequestComplete() {
        
    }
    
    @objc public func setupComplete() {
        
    }
    
    @objc public func setupComplete(_ arg1: Bool, info arg2: [AnyHashable : Any]!) {
        os_log("imagent setup completed: %d", arg1)
        
        guard ProcessInfo.processInfo.environment["BLNoBlocklist"] == nil else {
            return
        }
        
        ERSharedBlockList()._connect()
    }
}
