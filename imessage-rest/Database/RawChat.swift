//
//  RawChat.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

class RawChat: Record {
    required init(row: Row) {
        ROWID = row[Columns.ROWID]
        guid = row[Columns.guid]
        style = row[Columns.style]
        state = row[Columns.state]
        account_id = row[Columns.account_id]
        properties = row[Columns.properties]
        chat_identifier = row[Columns.chat_identifier]
        service_name = row[Columns.service_name]
        room_name = row[Columns.room_name]
        account_login = row[Columns.account_login]
        is_archived = row[Columns.is_archived]
        last_addressed_handle = row[Columns.last_addressed_handle]
        display_name = row[Columns.display_name]
        group_id = row[Columns.group_id]
        is_filtered = row[Columns.is_filtered]
        successful_query = row[Columns.successful_query]
        engram_id = row[Columns.engram_id]
        server_change_token = row[Columns.server_change_token]
        ck_sync_state = row[Columns.ck_sync_state]
        original_group_id = row[Columns.original_group_id]
        last_read_message_timestamp = row[Columns.last_read_message_timestamp]
        sr_server_change_token = row[Columns.sr_server_change_token]
        sr_ck_sync_state = row[Columns.sr_ck_sync_state]
        cloudkit_record_id = row[Columns.cloudkit_record_id]
        sr_cloudkit_record_id = row[Columns.sr_cloudkit_record_id]
        last_addressed_sim_id = row[Columns.last_addressed_sim_id]
        is_blackholed = row[Columns.is_blackholed]
        super.init(row: row)
    }
    
    override class var databaseTableName: String { "chat" }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.ROWID] = ROWID
        container[Columns.guid] = guid
        container[Columns.style] = style
        container[Columns.state] = state
        container[Columns.account_id] = account_id
        container[Columns.properties] = properties
        container[Columns.chat_identifier] = chat_identifier
        container[Columns.service_name] = service_name
        container[Columns.room_name] = room_name
        container[Columns.account_login] = account_login
        container[Columns.is_archived] = is_archived
        container[Columns.last_addressed_handle] = last_addressed_handle
        container[Columns.display_name] = display_name
        container[Columns.group_id] = group_id
        container[Columns.is_filtered] = is_filtered
        container[Columns.successful_query] = successful_query
        container[Columns.engram_id] = engram_id
        container[Columns.server_change_token] = server_change_token
        container[Columns.ck_sync_state] = ck_sync_state
        container[Columns.original_group_id] = original_group_id
        container[Columns.last_read_message_timestamp] = last_read_message_timestamp
        container[Columns.sr_server_change_token] = sr_server_change_token
        container[Columns.sr_ck_sync_state] = sr_ck_sync_state
        container[Columns.cloudkit_record_id] = cloudkit_record_id
        container[Columns.sr_cloudkit_record_id] = sr_cloudkit_record_id
        container[Columns.last_addressed_sim_id] = last_addressed_sim_id
        container[Columns.is_blackholed] = is_blackholed
    }

    enum Columns: String, ColumnExpression {
        case ROWID, guid, style, state, account_id, properties, chat_identifier, service_name, room_name, account_login, is_archived, last_addressed_handle, display_name, group_id, is_filtered, successful_query, engram_id, server_change_token, ck_sync_state, original_group_id, last_read_message_timestamp, sr_server_change_token, sr_ck_sync_state, cloudkit_record_id, sr_cloudkit_record_id, last_addressed_sim_id, is_blackholed
    }

    var ROWID: Int64?
    var guid: String?
    var style: Int64?
    var state: Int64?
    var account_id: String?
    var properties: Data?
    var chat_identifier: String?
    var service_name: String?
    var room_name: String?
    var account_login: String?
    var is_archived: Int64?
    var last_addressed_handle: String?
    var display_name: String?
    var group_id: String?
    var is_filtered: Int64?
    var successful_query: Int64?
    var engram_id: String?
    var server_change_token: String?
    var ck_sync_state: Int64?
    var original_group_id: String?
    var last_read_message_timestamp: Int64?
    var sr_server_change_token: String?
    var sr_ck_sync_state: Int64?
    var cloudkit_record_id: String?
    var sr_cloudkit_record_id: String?
    var last_addressed_sim_id: String?
    var is_blackholed: Int64?
}
