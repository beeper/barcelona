//
//  WeakLinks.swift
//  Barcelona
//
//  Created by Ian on 10/21/22.
//

import Foundation
import IMCore
import IMSharedUtilities

typealias IMCreateItemsFromSerializedArray_t = @convention(c) ([Any]) -> [IMItem]
typealias IMCreateSerializedItemsFromArray_t = @convention(c) ([IMItem]) -> [Any]?

let CBCreateItemsFromSerializedArray: IMCreateItemsFromSerializedArray_t = CBWeakLink(
    against: .privateFramework(name: "IMSharedUtilities"),
    .init(constraints: [.preVentura], symbol: "FZCreateIMMessageItemsFromSerializedArray"),
    .init(constraints: [.ventura], symbol: "IMCreateItemsFromSerializedArray")
)!

let CBCreateSerializedItemsFromArray: IMCreateSerializedItemsFromArray_t = CBWeakLink(
    against: .privateFramework(name: "IMSharedUtilities"),
    .init(constraints: [.preVentura], symbol: "FZCreateSerializedIMMessageItemsfromArray"),
    .init(constraints: [.ventura], symbol: "IMCreateSerializedItemsFromArray")
)!

@objc protocol IMMessageAcknowledgmentStringHelper_t: NSObjectProtocol {
    @objc(generateBackwardCompatibilityStringForMessageAcknowledgmentType:messageSummaryInfo:)
    static func generateBackwardCompatibilityString(
        forMessageAcknowledgmentType: Int64,
        messageSummaryInfo: [AnyHashable: Any]
    ) -> String!
}

@available(macOS, obsoleted: 13.0, message: "Only relevant for sending tapbacks; use IMTapbackSender instead")
func CBGeneratePreviewStringForAcknowledgmentType(_ associatedType: Int64, summaryInfo: [AnyHashable: Any]) -> String? {
    return NSClassFromString("IMMessageAcknowledgmentStringHelper")
        .map {
            unsafeBitCast($0, to: IMMessageAcknowledgmentStringHelper_t.Type.self)
        }?
        .generateBackwardCompatibilityString(
            forMessageAcknowledgmentType: associatedType,
            messageSummaryInfo: summaryInfo
        )
}
