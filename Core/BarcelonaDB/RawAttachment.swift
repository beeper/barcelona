//
//  RawAttachment.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

public struct ResourceOrigin: Codable, Hashable {
    public init?(chatID: String? = nil, handleID: String? = nil, date: Double? = nil) {
        self.chatID = chatID
        self.handleID = handleID
        self.date = date

        if chatID == nil, handleID == nil, date == nil {
            return nil
        }
    }

    public var chatID: String?
    public var handleID: String?
    public var date: Double?
}

public class RawAttachment: Record {
    public override class var databaseTableName: String { "attachment" }

    public static let messageAttachmentJoin = belongsTo(
        MessageAttachmentJoin.self,
        using: ForeignKey(["ROWID"], to: ["attachment_id"])
    )

    public required init(row: Row) {
        ROWID = row[Columns.ROWID]
        guid = row[Columns.guid]
        created_date = row[Columns.created_date]
        start_date = row[Columns.start_date]
        filename = row[Columns.filename]
        uti = row[Columns.uti]
        mime_type = row[Columns.mime_type]
        transfer_state = row[Columns.transfer_state]
        is_outgoing = row[Columns.is_outgoing]
        user_info = row[Columns.user_info]
        transfer_name = row[Columns.transfer_name]
        total_bytes = row[Columns.total_bytes]
        is_sticker = row[Columns.is_sticker]
        sticker_user_info = row[Columns.sticker_user_info]
        attribution_info = row[Columns.attribution_info]
        hide_attachment = row[Columns.hide_attachment]
        ck_sync_state = row[Columns.ck_sync_state]
        ck_server_change_token_blob = row[Columns.ck_server_change_token_blob]
        ck_record_id = row[Columns.ck_record_id]
        original_guid = row[Columns.original_guid]
        sr_ck_sync_state = row[Columns.sr_ck_sync_state]
        sr_ck_server_change_token_blob = row[Columns.sr_ck_server_change_token_blob]
        sr_ck_record_id = row[Columns.sr_ck_record_id]
        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.ROWID] = ROWID
        container[Columns.guid] = guid
        container[Columns.created_date] = created_date
        container[Columns.start_date] = start_date
        container[Columns.filename] = filename
        container[Columns.uti] = uti
        container[Columns.mime_type] = mime_type
        container[Columns.transfer_state] = transfer_state
        container[Columns.is_outgoing] = is_outgoing
        container[Columns.user_info] = user_info
        container[Columns.transfer_name] = transfer_name
        container[Columns.total_bytes] = total_bytes
        container[Columns.is_sticker] = is_sticker
        container[Columns.sticker_user_info] = sticker_user_info
        container[Columns.attribution_info] = attribution_info
        container[Columns.hide_attachment] = hide_attachment
        container[Columns.ck_sync_state] = ck_sync_state
        container[Columns.ck_server_change_token_blob] = ck_server_change_token_blob
        container[Columns.ck_record_id] = ck_record_id
        container[Columns.original_guid] = original_guid
        container[Columns.sr_ck_sync_state] = sr_ck_sync_state
        container[Columns.sr_ck_server_change_token_blob] = sr_ck_server_change_token_blob
        container[Columns.sr_ck_record_id] = sr_ck_record_id
    }

    public enum Columns: String, ColumnExpression {
        case ROWID, guid, created_date, start_date, filename, uti, mime_type, transfer_state, is_outgoing, user_info,
            transfer_name, total_bytes, is_sticker, sticker_user_info, attribution_info, hide_attachment, ck_sync_state,
            ck_server_change_token_blob, ck_record_id, original_guid, sr_ck_sync_state, sr_ck_server_change_token_blob,
            sr_ck_record_id
    }

    public var ROWID: Int64?
    public var guid: String?
    public var created_date: Int64?
    public var start_date: Int64?
    public var filename: String?
    public var uti: String?
    public var mime_type: String?
    public var transfer_state: Int64?
    public var is_outgoing: Int64?
    public var user_info: Data?
    public var transfer_name: String?
    public var total_bytes: Int64?
    public var is_sticker: Int64?
    public var sticker_user_info: Data?
    public var attribution_info: Data?
    public var hide_attachment: Int64?
    public var ck_sync_state: Int64?
    public var ck_server_change_token_blob: Data?
    public var ck_record_id: String?
    public var original_guid: String?
    public var sr_ck_sync_state: Int64?
    public var sr_ck_server_change_token_blob: Data?
    public var sr_ck_record_id: String?

    // MARK: - Overlay
    public var origin: ResourceOrigin?
}
