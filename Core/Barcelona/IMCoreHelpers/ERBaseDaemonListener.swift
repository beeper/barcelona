////  ERBaseDaemonListener.swift
//  Barcelona
//
//  Created by Eric Rabil on 9/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

open class ERBaseDaemonListener: NSObject, IMDaemonListenerProtocol {
    open func setupComplete(_ success: Bool, info: [AnyHashable : Any]!) {
        
    }
    
    open func setupComplete() {
        
    }
    
    open func pendingVCRequestComplete() {
        
    }
    
    open func pendingACRequestComplete() {
        
    }
    
    open func vcCapabilitiesChanged(_ capabilities: UInt32) {
        
    }
    
    open func defaultsChanged(_ defaults: [AnyHashable : Any]!, forService name: String!) {
        
    }
    
    open func activeAccountsChanged(_ accounts: [Any]!, forService name: String!) {
        
    }
    
    open func account(_ account: String!, defaults: [AnyHashable : Any]!, blockList: [Any]!, allowList: [Any]!, blockingMode: FZBlockingMode, blockIdleStatus blockIdle: Bool, status: [AnyHashable : Any]!, capabilities: UInt32, serviceLoginStatus: FZServiceStatus, loginStatusMessage message: String!) {
        
    }
    
    open func account(_ account: String!, loginStatusChanged status: FZServiceStatus, message: String!, reason: FZDisconnectReason, properties props: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, defaultsChanged defaults: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, capabilitiesChanged capabilities: UInt32) {
        
    }
    
    open func accountAdded(_ account: String!, defaults: [AnyHashable : Any]!, service internalName: String!) {
        
    }
    
    open func accountRemoved(_ account: String!) {
        
    }
    
    open func account(_ account: String!, buddyPropertiesChanged info: [Any]!) {
        
    }
    
    open func account(_ account: String!, blockListChanged blockList: [Any]!) {
        
    }
    
    open func account(_ account: String!, allowListChanged allowList: [Any]!) {
        
    }
    
    open func account(_ account: String!, blockingModeChanged blockingMode: FZBlockingMode) {
        
    }
    
    open func service(_ serviceID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, messagesUpdated messages: [Any]!) {
        
    }
    
    open func account(_ account: String!, blockIdleStatusChanged blockIdle: Bool) {
        
    }
    
    open func account(_ account: String!, buddyPictureChanged buddyID: String!, imageData data: Data!, imageHash hash: String!) {
        
    }
    
    open func account(_ account: String!, groupsChanged groups: [Any]!, error: Error!) {
        
    }
    
    open func account(_ account: String!, buddyProperties properties: [AnyHashable : Any]!, buddyPictures pictures: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, handleSubscriptionRequestFrom buddyInfo: [AnyHashable : Any]!, withMessage message: String!) {
        
    }
    
    open func account(_ accountID: String!, buddyInfo: [AnyHashable : Any]!, commandReceived command: NSNumber!, properties: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ accountID: String!, buddyInfo: [AnyHashable : Any]!, commandDelivered command: NSNumber!, properties: [AnyHashable : Any]!) {
        
    }
    
    open func chat(_ persistentIdentifier: String!, updated updateDictionary: [AnyHashable : Any]!) {
        
    }
    
    open func chat(_ persistentIdentifier: String!, propertiesUpdated properties: [AnyHashable : Any]!) {
        
    }
    
    open func chat(_ persistentIdentifier: String!, displayNameUpdated displayName: String!) {
        
    }
    
    open func chat(_ guid: String!, lastAddressedHandleUpdated lastAddressedHandle: String!) {
        
    }
    
    open func chat(_ guid: String!, lastAddressedSIMIDUpdated lastAddressedSIMID: String!) {
        
    }
    
    open func chat(_ persistentIdentifier: String!, isFilteredUpdated isFiltered: Bool) {
        
    }
    
    open func chat(_ persistentIdentifier: String!, engramIDUpdated engramID: String!) {
        
    }
    
    open func leftChat(_ persistentIdentifier: String!) {
        
    }
    
    open func engroupParticipantsUpdated(forChat persistentIdentifier: String!) {
        
    }
    
    open func loadedChats(_ chats: [[AnyHashable : Any]]!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, invitationReceived msg: IMMessageItem!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, updateProperties update: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, messageSent msg: IMMessageItem!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, messageReceived msg: IMItem!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, messagesReceived messages: [IMItem]!, messagesComingFromStorage fromStorage: Bool) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, messagesReceived messages: [IMItem]!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, messageUpdated msg: IMItem!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, notifySentMessage msg: IMMessageItem!, sendTime: NSNumber!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, messagesUpdated messages: [NSObject]!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, error: Error!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, groupID: String!, chatPersonCentricID personCentricID: String!, statusChanged status: FZChatStatus, handleInfo: [Any]!) {
        
    }
    
    open func account(_ accountUniqueID: String!, chat chatIdentifier: String!, style chatStyle: IMChatStyle, chatProperties properties: [AnyHashable : Any]!, member memberInfo: [AnyHashable : Any]!, statusChanged status: FZChatMemberStatus) {
        
    }
    
    open func messageQuery(_ queryID: String!, finishedWithResult message: IMMessageItem!, chatGUIDs: [Any]!) {
        
    }
    
    open func historyQuery(_ queryID: String!, chatID chatIdentifier: String!, services: [Any]!, finishedWithResult messages: [Any]!, limit: UInt) {
        
    }
    
    open func pagedHistoryQuery(_ queryID: String!, chatID: String!, services: [Any]!, numberOfMessagesBefore: UInt, numberOfMessagesAfter: UInt, finishedWithResult serializedItems: [Any]!) {
        
    }
    
    open func attachmentQuery(_ queryID: String!, chatID chatIdentifier: String!, services: [Any]!, finishedWithResult filenames: [Any]!) {
        
    }
    
    open func uncachedAttachmentCountQuery(_ queryID: String!, chatID chatIdentifier: String!, services: [Any]!, finishedWithResult countOfAttachmentsNotCachedLocally: NSNumber!) {
        
    }
    
    open func isDownloadingQuery(_ queryID: String!, chatID chatIdentifier: String!, services: [Any]!, finishedWithResult isCurrentlyDownloadingPurgedAssets: Bool) {
        
    }
    
    open func downloadedPurgedAssetBatch(forChatIDs chatIdentifiers: [String]!, completedTransferGUIDs transferGUIDs: [String]!) {
        
    }
    
    open func finishedDownloadingPurgedAssets(forChatIDs chatIdentifiers: [String]!) {
        
    }
    
    open func mark(asSpamQuery queryID: String!, chatID chatIdentifier: String!, services: [Any]!, finishedWithResult countOfMessagesMarkedAsSpam: NSNumber!) {
        
    }
    
    open func historicalMessageGUIDsDeleted(_ deletedGUIDs: [String]!, chatGUIDs: [String]!, queryID: String!) {
        
    }
    
    open func frequentRepliesQuery(_ queryID: String!, chatID chatIdentifier: String!, services queryServices: [Any]!, finishedWithResult frequentReplies: [Any]!, limit: UInt) {
        
    }
    
    open func chatLoaded(withChatIdentifier chatIdentifier: String!, chats chatDictionaries: [Any]!) {
        
    }
    
    open func standaloneFileTransferRegistered(_ guid: String!) {
        
    }
    
    open func fileTransfer(_ guid: String!, createdWithProperties properties: [AnyHashable : Any]!) {
        
    }
    
    open func fileTransfer(_ guid: String!, updatedWithProperties properties: [AnyHashable : Any]!) {
        
    }
    
    open func fileTransfers(_ guids: [Any]!, createdWithLocalPaths paths: [Any]!) {
        
    }
    
    open func fileTransfer(_ guid: String!, updatedWithCurrentBytes currentBytes: UInt64, totalBytes: UInt64, averageTransferRate: UInt64) {
        
    }
    
    open func fileTransfer(_ guid: String!, highQualityDownloadSucceededWithPath path: String!) {
        
    }
    
    open func fileTransferHighQualityDownloadFailed(_ guid: String!) {
        
    }
    
    open func account(_ account: String!, conference: String!, receivedInvitationFrom buddyInfo: [AnyHashable : Any]!, properties props: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, conference: String!, receivedResponseToInvitationFrom buddyInfo: [AnyHashable : Any]!, properties props: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, conference: String!, receivedCancelInvitationFrom buddyInfo: [AnyHashable : Any]!, properties props: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, conference: String!, receivedCounterProposalFrom buddyInfo: [AnyHashable : Any]!, properties props: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, conference: String!, receivedUpdateFrom buddyInfo: [AnyHashable : Any]!, data info: Data!) {
        
    }
    
    open func account(_ account: String!, conference: String!, receivedAVMessage messageType: UInt32, from buddyInfo: [AnyHashable : Any]!, sessionID: UInt32, userInfo: [AnyHashable : Any]! = [:]) {
        
    }
    
    open func account(_ account: String!, conference: String!, changedToNewConferenceID newConferenceID: String!) {
        
    }
    
    open func account(_ account: String!, conference: String!, peerIDChangedFromID oldOld: String!, toID newID: String!) {
        
    }
    
    open func account(_ account: String!, conference: String!, peerID peer: String!, propertiesUpdated properties: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, conference: String!, invitationSentSuccessfully success: Bool) {
        
    }
    
    open func account(_ account: String!, avAction action: UInt32, withArguments arguments: [AnyHashable : Any]!, toAVChat avChat: String!, isVideo: Bool) {
        
    }
    
    open func showInvalidCertNotification(forAccount account: String!) {
        
    }
    
    open func showForgotPasswordNotification(forAccount account: String!) {
        
    }
    
    open func property(_ propertyName: String!, changedTo value: Any!, from oldValue: Any!) {
        
    }
    
    open func persistentProperty(_ propertyName: String!, changedTo value: Any!, from oldValue: Any!) {
        
    }
    
    open func account(_ account: String!, statusChanged status: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, postedError error: Error!) {
        
    }
    
    open func account(_ account: String!, relay: String!, handleInitate dictionary: [AnyHashable : Any]!, fromPerson personInfo: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, relay: String!, handleUpdate dictionary: [AnyHashable : Any]!, fromPerson personInfo: [AnyHashable : Any]!) {
        
    }
    
    open func account(_ account: String!, relay: String!, handleCancel dictionary: [AnyHashable : Any]!, fromPerson personInfo: [AnyHashable : Any]!) {
        
    }
    
    open func databaseUpdated() {
        
    }
    
    open func databaseUpdated(_ stamp: String!) {
        
    }
    
    open func databaseFull() {
        
    }
    
    open func databaseNoLongerFull() {
        
    }
    
    open func databaseChatSpamUpdated(_ chatGUID: String!) {
        
    }
    
    open func unreadCountChanged(_ unreadCount: Int) {
        
    }
    
    open func lastFailedMessageDateChanged(_ failedDate: Int64) {
        
    }
    
    open func displayPinCode(forAccount account: String!, pinCode: NSNumber!, deviceName: String!, deviceType: String!, phoneNumber: String!) {
        
    }
    
    open func pinCodeAlertCompleted(_ account: String!, deviceName: String!, deviceType: String!, phoneNumber: String!, responseFromDevice: Bool, wasCancelled: Bool) {
        
    }
    
    open func stickerPackUpdated(_ stickerPackDictionary: [AnyHashable : Any]!) {
        
    }
    
    open func stickerPackRemoved(_ stickerPackGUID: [Any]!) {
        
    }
    
    open func updateCloudKitState() {
        
    }
    
    open func updateCloudKitState(with stateDictionary: [AnyHashable : Any]!) {
        
    }
    
    open func didAttemptToSetEnabled(to targetEnabled: Bool, result didSucceed: Bool) {
        
    }
    
    open func didPerformAdditionalStorageRequiredCheck(withSuccess didSucceed: Bool, additionalStorageRequired: UInt64, forAccountId iCloudAccountId: String!, error: Error!) {
        
    }
    
    open func didAttempt(toDisableAllDevicesResult didSucceed: Bool) {
        
    }
    
    open func didFetchSyncStateStats(_ stats: [AnyHashable : Any]!) {
        
    }
    
    open func didAttempt(toDisableiCloudBackups result: Int, error: Error?) {
        
    }
    
    open func oneTimeCodesDidChange(_ validOneTimeCodes: [[AnyHashable : Any]]!) {
        
    }
    
    open func receivedUrgentRequest(forMessages messageGUIDs: [String]!) {
        
    }
    
    open func didFetchCloudKitSyncDebuggingInfo(_ info: [AnyHashable : Any]!) {
        
    }
    
    open func lastMessage(forAllChats chatIDToLastMessageDictionary: [AnyHashable : Any]!) {
        
    }
    
    open func groupPhotoUpdated(forChatIdentifier chatIdentifier: String!, style: IMChatStyle, account: String!, userInfo: [AnyHashable : Any]! = [:]) {
        
    }
}
