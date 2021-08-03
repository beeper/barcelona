//
//  InternalAttachment+LazilyResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

// MARK: - Begin Deprecated
internal extension RawAttachment {
    /// Constructs an internal attachment representation centered around a resource origin
    /// - Parameter origin: origin to pass to the internal attachment
    /// - Returns: an internal attachment object
    func internalAttachment(withOrigin origin: ResourceOrigin? = nil) -> BarcelonaAttachment? {
        guard let guid = guid, let path = filename as NSString? else {
            return nil
        }
        
        return BarcelonaAttachment(guid: guid, originalGUID: original_guid, path: path.expandingTildeInPath, bytes: UInt64(total_bytes ?? 0), incoming: (is_outgoing ?? 0) == 0, mime: mime_type, uti: uti, origin: origin)
    }
    
    @usableFromInline
    var internalAttachment: BarcelonaAttachment? {
        internalAttachment()
    }
}
// MARK: - End Deprecated

extension BarcelonaAttachment: LazilyResolvable, ConcreteLazilyBasicResolvable {
    public static func lazyResolve(withIdentifiers identifiers: [String]) -> Promise<[BarcelonaAttachment]> {
        DBReader.shared.attachments(withGUIDs: identifiers).compactMap(\.internalAttachment)
    }
}
