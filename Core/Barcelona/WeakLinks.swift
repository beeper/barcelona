//
//  WeakLinks.swift
//  Barcelona
//
//  Created by Ian on 10/21/22.
//

import Foundation
import IMSharedUtilities

typealias IMCreateItemsFromSerializedArray_t = @convention(c) ([Any]) -> [IMItem]
typealias IMCreateSerializedItemsFromArray_t = @convention(c) ([IMItem]) -> [Any]?

let CBCreateItemsFromSerializedArray: IMCreateItemsFromSerializedArray_t = CBWeakLink(
    against: .privateFramework(name: "IMSharedUtilities"),
    .init(constraints: [.preVentura], symbol: "FZCreateIMMessageItemsFromSerializedArray"),
    .init(constraints: [.ventura],    symbol: "IMCreateItemsFromSerializedArray")
)!

let CBCreateSerializedItemsFromArray: IMCreateSerializedItemsFromArray_t = CBWeakLink(
    against: .privateFramework(name: "IMSharedUtilities"),
    .init(constraints: [.preVentura], symbol: "FZCreateSerializedIMMessageItemsfromArray"),
    .init(constraints: [.ventura],    symbol: "IMCreateSerializedItemsFromArray")
)!

@objc protocol IMMessageAcknowledgmentStringHelper_t: NSObjectProtocol {
    @objc(generateBackwardCompatibilityStringForMessageAcknowledgmentType:messageSummaryInfo:)
    static func generateBackwardCompatibilityString(forMessageAcknowledgmentType: Int64, messageSummaryInfo: [AnyHashable: Any]) -> String!
}

import IMCore

func CBGeneratePreviewStringForAcknowledgmentItem(_ item: IMMessage) -> String! {
    // Xcode 14.1 shipped with 5.7.1, while Xcode 14.0.1 contains 5.7.
    // Xcode 14.1 was the first one to contain the Ventura SDK, which contains symbols to link against to call item.tapback(),
    // so we conditionally compile against it to only compile this when available.
#if compiler(>=5.7.1)
    if #available(macOS 13, iOS 16, watchOS 9, *) {
        guard let tapback = item.tapback() else {
            return nil
        }
        return tapback.previewString(withMessageSummaryInfo: item.messageSummaryInfo, senderDisplayName: item.sender?._displayNameWithAbbreviation, isFromMe: item.isFromMe)
    }
#endif // Compiler check

    return NSClassFromString("IMMessageAcknowledgmentStringHelper").map {
        unsafeBitCast($0, to: IMMessageAcknowledgmentStringHelper_t.Type.self)
    }?.generateBackwardCompatibilityString(forMessageAcknowledgmentType: item.associatedMessageType, messageSummaryInfo: item.messageSummaryInfo)
}
