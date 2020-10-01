//
//  RawMessage.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB
import NIO

/**
 Represents a message record in the chat.db file
 */
class RawMessage: Record {
    override class var databaseTableName: String { "message" }
    
    static let messageChatJoin = belongsTo(ChatMessageJoin.self, using: ForeignKey(["ROWID"], to: ["message_id"]))
    static let messageHandleJoin = belongsTo(RawHandle.self, key: "handle", using: ForeignKey([RawMessage.Columns.handle_id], to: [RawHandle.Columns.ROWID]))
    static let messageOtherHandleJoin = belongsTo(RawHandle.self, key: "otherHandle", using: ForeignKey([RawMessage.Columns.other_handle], to: [RawHandle.Columns.ROWID]))
    static let messageAttachmentJoin = belongsTo(MessageAttachmentJoin.self, using: ForeignKey([RawMessage.Columns.ROWID], to: [MessageAttachmentJoin.Columns.message_id]))
    
    required init(row: Row) {
        account = row[Columns.account]
        account_guid = row[Columns.account_guid]
        associated_message_guid = row[Columns.associated_message_guid]
        associated_message_range_length = row[Columns.associated_message_range_length]
        associated_message_range_location = row[Columns.associated_message_range_location]
        associated_message_type = row[Columns.associated_message_type]
        attributedBody = row[Columns.attributedBody]
        balloon_bundle_id = row[Columns.balloon_bundle_id]
        cache_has_attachments = row[Columns.cache_has_attachments]
        cache_roomnames = row[Columns.cache_roomnames]
        ck_record_change_tag = row[Columns.ck_record_change_tag]
        ck_record_id = row[Columns.ck_record_id]
        ck_sync_state = row[Columns.ck_sync_state]
        country = row[Columns.country]
        date = row[Columns.date]
        date_delivered = row[Columns.date_delivered]
        date_played = row[Columns.date_played]
        date_read = row[Columns.date_read]
        destination_caller_id = row[Columns.destination_caller_id]
        error = row[Columns.error]
        expire_state = row[Columns.expire_state]
        expressive_send_style_id = row[Columns.expressive_send_style_id]
        group_action_type = row[Columns.group_action_type]
        group_title = row[Columns.group_title]
        guid = row[Columns.guid]
        handle_id = row[Columns.handle_id]
        has_dd_results = row[Columns.has_dd_results]
        is_archive = row[Columns.is_archive]
        is_audio_message = row[Columns.is_audio_message]
        is_auto_reply = row[Columns.is_auto_reply]
        is_corrupt = row[Columns.is_corrupt]
        is_delayed = row[Columns.is_delayed]
        is_delivered = row[Columns.is_delivered]
        is_emote = row[Columns.is_emote]
        is_empty = row[Columns.is_empty]
        is_expirable = row[Columns.is_expirable]
        is_finished = row[Columns.is_finished]
        is_forward = row[Columns.is_forward]
        is_from_me = row[Columns.is_from_me]
        is_played = row[Columns.is_played]
        is_prepared = row[Columns.is_prepared]
        is_read = row[Columns.is_read]
        is_sent = row[Columns.is_sent]
        is_service_message = row[Columns.is_service_message]
        is_spam = row[Columns.is_spam]
        is_system_message = row[Columns.is_system_message]
        item_type = row[Columns.item_type]
        message_action_type = row[Columns.message_action_type]
        message_source = row[Columns.message_source]
        message_summary_info = row[Columns.message_summary_info]
        other_handle = row[Columns.other_handle]
        payload_data = row[Columns.payload_data]
        replace = row[Columns.replace]
        reply_to_guid = row[Columns.reply_to_guid]
        ROWID = row[Columns.ROWID]
        service = row[Columns.service]
        service_center = row[Columns.service_center]
        share_direction = row[Columns.share_direction]
        share_status = row[Columns.share_status]
        sort_id = row[Columns.sort_id]
        sr_ck_record_change_tag = row[Columns.sr_ck_record_change_tag]
        sr_ck_record_id = row[Columns.sr_ck_record_id]
        sr_ck_sync_state = row[Columns.sr_ck_sync_state]
        subject = row[Columns.subject]
        text = row[Columns.text]
        time_expressive_send_played = row[Columns.time_expressive_send_played]
        type = row[Columns.type]
        version = row[Columns.version]
        was_data_detected = row[Columns.was_data_detected]
        was_deduplicated = row[Columns.was_deduplicated]
        was_downgraded = row[Columns.was_downgraded]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.account] = account
        container[Columns.account_guid] = account_guid
        container[Columns.associated_message_guid] = associated_message_guid
        container[Columns.associated_message_range_length] = associated_message_range_length
        container[Columns.associated_message_range_location] = associated_message_range_location
        container[Columns.associated_message_type] = associated_message_type
        container[Columns.attributedBody] = attributedBody
        container[Columns.balloon_bundle_id] = balloon_bundle_id
        container[Columns.cache_has_attachments] = cache_has_attachments
        container[Columns.cache_roomnames] = cache_roomnames
        container[Columns.ck_record_change_tag] = ck_record_change_tag
        container[Columns.ck_record_id] = ck_record_id
        container[Columns.ck_sync_state] = ck_sync_state
        container[Columns.country] = country
        container[Columns.date] = date
        container[Columns.date_delivered] = date_delivered
        container[Columns.date_played] = date_played
        container[Columns.date_read] = date_read
        container[Columns.destination_caller_id] = destination_caller_id
        container[Columns.error] = error
        container[Columns.expire_state] = expire_state
        container[Columns.expressive_send_style_id] = expressive_send_style_id
        container[Columns.group_action_type] = group_action_type
        container[Columns.group_title] = group_title
        container[Columns.guid] = guid
        container[Columns.handle_id] = handle_id
        container[Columns.has_dd_results] = has_dd_results
        container[Columns.is_archive] = is_archive
        container[Columns.is_audio_message] = is_audio_message
        container[Columns.is_auto_reply] = is_auto_reply
        container[Columns.is_corrupt] = is_corrupt
        container[Columns.is_delayed] = is_delayed
        container[Columns.is_delivered] = is_delivered
        container[Columns.is_emote] = is_emote
        container[Columns.is_empty] = is_empty
        container[Columns.is_expirable] = is_expirable
        container[Columns.is_finished] = is_finished
        container[Columns.is_forward] = is_forward
        container[Columns.is_from_me] = is_from_me
        container[Columns.is_played] = is_played
        container[Columns.is_prepared] = is_prepared
        container[Columns.is_read] = is_read
        container[Columns.is_sent] = is_sent
        container[Columns.is_service_message] = is_service_message
        container[Columns.is_spam] = is_spam
        container[Columns.is_system_message] = is_system_message
        container[Columns.item_type] = item_type
        container[Columns.message_action_type] = message_action_type
        container[Columns.message_source] = message_source
        container[Columns.message_summary_info] = message_summary_info
        container[Columns.other_handle] = other_handle
        container[Columns.payload_data] = payload_data
        container[Columns.replace] = replace
        container[Columns.reply_to_guid] = reply_to_guid
        container[Columns.ROWID] = ROWID
        container[Columns.service] = service
        container[Columns.service_center] = service_center
        container[Columns.share_direction] = share_direction
        container[Columns.share_status] = share_status
        container[Columns.sort_id] = sort_id
        container[Columns.sr_ck_record_change_tag] = sr_ck_record_change_tag
        container[Columns.sr_ck_record_id] = sr_ck_record_id
        container[Columns.sr_ck_sync_state] = sr_ck_sync_state
        container[Columns.subject] = subject
        container[Columns.text] = text
        container[Columns.time_expressive_send_played] = time_expressive_send_played
        container[Columns.type] = type
        container[Columns.version] = version
        container[Columns.was_data_detected] = was_data_detected
        container[Columns.was_deduplicated] = was_deduplicated
        container[Columns.was_downgraded] = was_downgraded
    }

    enum Columns: String, ColumnExpression {
        case account, account_guid, associated_message_guid, associated_message_range_length, associated_message_range_location, associated_message_type, attributedBody, balloon_bundle_id, cache_has_attachments, cache_roomnames, ck_record_change_tag, ck_record_id, ck_sync_state, country, date, date_delivered, date_played, date_read, destination_caller_id, error, expire_state, expressive_send_style_id, group_action_type, group_title, guid, handle_id, has_dd_results, is_archive, is_audio_message, is_auto_reply, is_corrupt, is_delayed, is_delivered, is_emote, is_empty, is_expirable, is_finished, is_forward, is_from_me, is_played, is_prepared, is_read, is_sent, is_service_message, is_spam, is_system_message, item_type, message_action_type, message_source, message_summary_info, other_handle, payload_data, replace, reply_to_guid, ROWID, service, service_center, share_direction, share_status, sort_id, sr_ck_record_change_tag, sr_ck_record_id, sr_ck_sync_state, subject, text, time_expressive_send_played, type, version, was_data_detected, was_deduplicated, was_downgraded
    }
    
    var account: String?
    var account_guid: String?
    var associated_message_guid: String?
    var associated_message_range_length: Int64?
    var associated_message_range_location: Int64?
    var associated_message_type: Int64?
    var attributedBody: Data?
    var balloon_bundle_id: String?
    var cache_has_attachments: Int64?
    var cache_roomnames: String?
    var ck_record_change_tag: String?
    var ck_record_id: String?
    var ck_sync_state: Int64?
    var country: String?
    var date: Int64?
    var date_delivered: Int64?
    var date_played: Int64?
    var date_read: Int64?
    var destination_caller_id: String?
    var error: Int64?
    var expire_state: Int64?
    var expressive_send_style_id: String?
    var group_action_type: Int64?
    var group_title: String?
    var guid: String?
    var handle_id: Int64?
    var has_dd_results: Int64?
    var is_archive: Int64?
    var is_audio_message: Int64?
    var is_auto_reply: Int64?
    var is_corrupt: Int64?
    var is_delayed: Int64?
    var is_delivered: Int64?
    var is_emote: Int64?
    var is_empty: Int64?
    var is_expirable: Int64?
    var is_finished: Int64?
    var is_forward: Int64?
    var is_from_me: Int64?
    var is_played: Int64?
    var is_prepared: Int64?
    var is_read: Int64?
    var is_sent: Int64?
    var is_service_message: Int64?
    var is_spam: Int64?
    var is_system_message: Int64?
    var item_type: Int64?
    var message_action_type: Int64?
    var message_source: Int64?
    var message_summary_info: Data?
    var other_handle: Int64?
    var payload_data: Data?
    var replace: Int64?
    var reply_to_guid: String?
    var ROWID: Int64
    var service: String?
    var service_center: String?
    var share_direction: Int64?
    var share_status: Int64?
    var sort_id: Int64?
    var sr_ck_record_change_tag: String?
    var sr_ck_record_id: String?
    var sr_ck_sync_state: Int64?
    var subject: String?
    var text: String?
    var time_expressive_send_played: Int64?
    var type: Int64?
    var version: Int64?
    var was_data_detected: Int64?
    var was_deduplicated: Int64?
    var was_downgraded: Int64?
}

extension DBReader {
    func rowID(forMessageGUID guid: String) -> EventLoopFuture<Int64?> {
        let promise = eventLoop.makePromise(of: Int64?.self)
        
        pool.asyncRead {
            switch $0 {
            case .failure(let error):
                promise.fail(error)
            case .success(let db):
                do {
                    let ROWID = try RawMessage
                        .select(RawMessage.Columns.ROWID, as: Int64.self)
                        .filter(RawMessage.Columns.guid == guid)
                        .fetchOne(db)
                    
                    promise.succeed(ROWID)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
}
