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

    private static let log = Logger(label: "IDSResolver")
    private static let handleQueue = DispatchQueue.init(label: "HandleIDS")
    private static let idsListenerID = "SOIDSListener-com.apple.imessage-rest"

    // Used for SendMessageCLICommand; allows you to overwrite specific ids
    // so that when you request for their statuses, it always says that they're
    // available through IDS (or not available, whatever you want)
    public static var overwrittenStatuses = [String: Int64]()

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

    public static func hijackIDSResponse(in response: inout OS_xpc_object) async {
        guard let swiftDict = response.toSwiftDictionary() else {
            log.debug("Got reply for __sendMessage, is object: \(String(describing: response))")
            return
        }

        // If we can turn it into a parseable dictionary,
        // then print that instead of just the object
        log.debug("Got reply for __sendMessage, is dict: \(swiftDict.singleLineDebugDescription)")

        // I think the IDSIDKTData type is not available in < ventura, so we can't proceed
        // if that's the case
        guard #available(macOS 13.0, *), let dest = swiftDict["destinations"] as? Data else {
            return
        }

        func reinsertData(
            statuses: [String: Int64],
            _ getData: @escaping ([String: Int64]) throws -> Data
        ) async {
            // If all the statuses say that they're available,
            // then we don't need to ask anybody else about statuses
            if statuses.values.allSatisfy({ $0 == 1 }) {
                return
            }

            // Query echobot or whatever for the correct statuses
            let realValues: [String: Int64]
            do {
                realValues = try await IDSResolver.queryMule(for: Array(statuses.keys))
            } catch {
                log.error("Couldn't query mule for real statuses of \(statuses.keys): \(error)")
                return
            }

            do {
                let dataVal = try getData(realValues)

                // and if we got a good value, insert them
                dataVal.withUnsafeBytes {
                    guard let dataPtr = $0.baseAddress else {
                        log.warning("Couldn't get baseAddress for data pointer to re-processed data")
                        return
                    }
                    xpc_dictionary_set_data(response, "destinations", dataPtr, dataVal.count)
                }
            } catch {
                log.warning("Couldn't convert new statuses to data in __sendMessage: \(error)")
            }
        }

        // Unarchive it to a more understandable format
        if let obj = (try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [
            NSDictionary.classForKeyedUnarchiver(),
            NSString.classForKeyedUnarchiver(),
            NSUUID.classForKeyedUnarchiver(),
            IDSIDInfoResult.classForKeyedUnarchiver(),
            IDSIDKTData.classForKeyedUnarchiver()
        ], from: dest) as? [String: IDSIDInfoResult]) {
            log.debug("__sendMessage was invoked for an ids query, returned archive is: \(obj.mapValues{ $0.status() }.singleLineDebugDescription)")

            await reinsertData(statuses: obj.mapValues { $0.status() }) { realValues in
                let results: [String: IDSIDInfoResult] = realValues.map {
                    IDSIDInfoResult(uri: $0, status: $1, endpoints: nil, ktData: nil, gameCenterData: nil)
                }.reduce(into: [:], { $0[$1.uri()] = $1 })

                return try NSKeyedArchiver.archivedData(withRootObject: results, requiringSecureCoding: false)
            }
        } else if let obj = try? PropertyListSerialization.propertyList(from: dest, format: nil) as? any CustomDebugStringConvertible {
            log.debug("__sendMessage was invoked for an ids query, returned plist is: \(obj.singleLineDebugDescription)")

            // It should be in this format, but we just want to make sure
            guard let obj = obj as? [String: [String: Int64]],
                  let stat = obj["com.apple.madrid"] else {
                log.warning("__sendMessage obj was a plist, but not a dictionary; can't continue querying mule")
                return
            }

            await reinsertData(statuses: stat) { realValues in
                return try PropertyListSerialization.data(
                    fromPropertyList: ["com.apple.madrid": realValues.mapValues { $0 as NSNumber }],
                    format: .binary,
                    options: 0
                )
            }
        } else {
            // If we don't know what format it's in, just log and exit :(
            log.warning("__sendMessage return value was not a known decodable format: \(dest)")
        }
    }

    /// Queries echobot (or whatever other mule we're using) for the actual status of the given identifiers
    ///  - Parameters:
    ///    - ids: the identifiers to query, containing their `mailto:` or `tel:` prefixes
    ///  - Returns: Dictionary mapping the destinations to the Int64 value of their state (as is returned by IDSIDQueryController)
    static func queryMule(for ids: [String]) async throws -> [String: Int64] {
        // hehe everything's available
        ids.reduce(into: [:]) { dict, id in
            // If any of the overwritten IDs are this id (or this id contains one of them,
            // such as how "tel:+12345678900" contains "+12345678900"), then it's available
            let overwrittenStatus = Self.overwrittenStatuses.first {
                id.contains($0.key)
            }?.value

            dict[id] = overwrittenStatus ?? 0
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
