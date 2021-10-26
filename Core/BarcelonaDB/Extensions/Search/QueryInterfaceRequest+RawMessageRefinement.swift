//
//  QueryInterfaceRequest+RawMessageRefinement.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

internal extension QueryInterfaceRequest where T == RawMessage {
    func joiningOnHandlesWhenNotEmpty(handles: [String]) -> Self {
        /// the handle_id is the recipient when from_me is 0, other_handle is the recipient when from_me is 1
        if handles.count > 0 {
            return joining(optional: RawMessage.messageHandleJoin.filter(handles.contains(RawHandle.Columns.id)))
        } else {
            return self
        }
    }
    
    func filterTextWhenNotEmpty(text: String?) -> Self {
        if let text = text, text.count > 0 {
            return filter(RawMessage.Columns.text.uppercased.like("%\(text)%"))
        } else {
            return self
        }
    }
    
    func filterBundleIDWhenNotEmpty(bundleID: String?) -> Self {
        if let bundleID = bundleID, bundleID.count > 0 {
            return filter(RawMessage.Columns.balloon_bundle_id == bundleID)
        } else {
            return self
        }
    }
}
