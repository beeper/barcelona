////  IDS.swift
//  Barcelona
//
//  Created by Eric Rabil on 9/3/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import CommonUtilities
import Foundation
import IDS
import IDSFoundation
import IMFoundation
import Logging

enum IDSResolverError: Error {
    /// Handle isn't an email, phone number, or business ID.
    case unknownHandleStyle
    /// IDS status was not found in the response.
    case statusNotFound
}

public class IDSResolver {

    // MARK: - Properties

    private static let sharedController: IDSIDQueryController = IDSIDQueryController.sharedInstance()!

    public static let idsListenerID = "SOIDSListener-com.apple.imessage-rest"
    private static let log = Logger(label: "IDSResolver")
    private static let handleQueue = DispatchQueue.init(label: "HandleIDS")

    // MARK: - Methods

    /// Resolve the IDS status for an id.
    /// - Parameters:
    ///   - id: Handle to check the status for.
    ///   - service: The service to check the status for.
    ///   - force: Skip IDS service cache.
    /// - Returns: Resolved and enhanced ID with the URI prefix stripped and the status for that ID.
    static func resolveStatus(
        for id: String,
        on service: IMServiceStyle,
        force: Bool = false
    ) async throws -> (String, IDSState) {
        let handleStyle = try handleStyle(for: id)
        let destination = try destination(for: id, handleStyle: handleStyle)

        switch service {
        case .SMS:
            guard Registry.sharedInstance.smsServiceEnabled else {
                log.info("Bailing SMS IDS query, sms service is not enabled")
                return (id, .unavailable)
            }

            return (id, handleStyle == .phoneNumber ? .available : .unavailable)
        case .Phone:
            guard Registry.sharedInstance.callServiceEnabled else {
                log.info("Bailing phone IDS query, calling is not enabled")
                return (id, .unavailable)
            }

            return (id, handleStyle == .phoneNumber ? .available : .unavailable)
        case .FaceTime, .iMessage:
            let statuses = try await resolveIDS(for: [destination], on: service, force: force)
            guard let resolvedID = statuses.keys.first, let status = statuses.values.first else {
                throw IDSResolverError.statusNotFound
            }
            return (IDSURI(prefixedURI: resolvedID)!.unprefixedURI, status)
        }
    }

    /// Query IDS with or without cached results.
    /// - Parameters:
    ///   - destinations: Destination handles.
    ///   - service: ``IMServiceStyle`` to query the status for.
    ///   - force: If `true`, use a force query that skips the cache in IDS side.
    /// - Returns: Dictionary mapping the destinations to ``IDSState``.
    private static func resolveIDS(
        for destinations: [String],
        on service: IMServiceStyle,
        force: Bool
    ) async throws -> [String: IDSState] {
        let result =
            force
            ? await forceRefreshIDStatus(for: destinations, with: service.idsIdentifier)
            : await refreshIDStatus(for: destinations, with: service.idsIdentifier)

        return
            result
            .mapValues {
                IDSState(rawValue: Int(truncating: $0))
            }
    }

    /// Wraps
    /// `IDSIDQueryController.forceRefreshIDStatus(forDestinations:service:listenerID:queue:completionBlock:)`
    /// as an `async` method.
    /// - Parameters:
    ///   - destinations: String from `IDSCopyIDFor[handle type]Address` methods.
    ///   - serviceIDSIdentifier: ``IMServiceStyle/idsIdentifier`` of the ``IMServiceStyle``.
    /// - Returns: A dictionary mapping IDs to ``IDSState``  raw values through `NSNumber`s.
    @MainActor
    private static func forceRefreshIDStatus(
        for destinations: [String],
        with serviceIDSIdentifier: String
    ) async -> [String: NSNumber] {
        await withCheckedContinuation { continuation in
            sharedController.forceRefreshIDStatus(
                forDestinations: destinations,
                service: serviceIDSIdentifier,
                listenerID: idsListenerID,
                queue: handleQueue
            ) {
                continuation.resume(returning: $0)
            }
        }
    }

    /// Wraps
    /// `IDSIDQueryController.refreshIDStatus(forDestinations:service:listenerID:queue:errorCompletionBlock:)`
    /// as an `async` method.
    /// - Parameters:
    ///   - destinations: String from `IDSCopyIDFor[handle type]Address` methods.
    ///   - serviceIDSIdentifier: ``IMServiceStyle/idsIdentifier`` of the ``IMServiceStyle``.
    /// - Returns: A dictionary mapping IDs to ``IDSState``  raw values through `NSNumber`s.
    @MainActor
    private static func refreshIDStatus(
        for destinations: [String],
        with serviceIDSIdentifier: String
    ) async -> [String: NSNumber] {
        await withCheckedContinuation { continuation in
            sharedController.refreshIDStatus(
                forDestinations: destinations,
                service: serviceIDSIdentifier,
                listenerID: idsListenerID,
                queue: handleQueue
            ) {
                continuation.resume(returning: $0)
            }
        }
    }

    /// Calls the relevant `IDSCopyIDFor[handle style]` to get the destination.
    /// - Throws: `IDSResolverError.unknownHandleStyle` if `handleStyle` is ``HandleIDStyle/unknown``.
    private static func destination(for id: String, handleStyle: HandleIDStyle) throws -> String {
        log.debug("Getting destination for id: \(id), handleStyle: \(handleStyle)")
        switch handleStyle {
        case .email:
            return IDSCopyIDForEmailAddress(id as CFString)
        case .businessID:
            return IDSCopyIDForBusinessID(id as CFString)
        case .phoneNumber:
            return IDSCopyIDForPhoneNumber(id as CFString)
        case .unknown:
            throw IDSResolverError.unknownHandleStyle
        }
    }

    /// Get the service style for the given ID.
    ///
    /// The service style is determined by checking (in order) if the ID is:
    /// - an email
    /// - a phone number
    /// - a business ID
    ///
    /// - Parameter id: String identifier.
    /// - Returns: ``HandleIDStyle`` based on the first matching format. ``HandleIDStyle/unknown`` is not used, the method will `throw` insteand.
    /// - Throws: `IDSResolverError.unknownHandleStyle` if the format can't be recognized.
    private static func handleStyle(for id: String) throws -> HandleIDStyle {
        switch true {
        case IMStringIsEmail(id):
            return .email
        case IMStringIsPhoneNumber(id):
            return .phoneNumber
        case IMStringIsBusinessID(id):
            return .businessID
        default:
            throw IDSResolverError.unknownHandleStyle
        }
    }
}
