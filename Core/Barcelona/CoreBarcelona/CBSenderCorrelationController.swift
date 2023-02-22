//
//  CBSenderCorrelationController.swift
//  Barcelona
//
//  Created by Eric Rabil on 3/12/22.
//

import CoreData
import Foundation
import GRDB
import IDS
import IMCore
import IMSharedUtilities
import Logging
import Pwomise
import SwiftCLI

extension IMChat {
    var styleSeparator: String {
        if isGroup {
            return ";+;"
        } else {
            return ";-;"
        }
    }

    var guidPrefix: String {
        account.serviceName + styleSeparator
    }

    /// If the chat is a DM, returns the correlation identifier of the recipient if it is known
    public var correlationIdentifier: String? {
        guard isSingle && CBFeatureFlags.correlateChats else {
            return nil
        }
        return recipient?.senderCorrelationID
    }
}

extension String {
    var droppingURIPrefix: String {
        IDSDestination(uri: self).uri().unprefixedURI
    }
}

extension IMChat: Identifiable {
    public var id: String {
        chatIdentifier
    }
}

extension FileManager {
    public func libraryURLForCurrentUser() throws -> URL {
        try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    public func barcelonaDirectory() throws -> URL {
        let url = try libraryURLForCurrentUser().appendingPathComponent("Barcelona")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

extension NSAttributeDescription {
    static func stringNamed(_ name: String) -> NSAttributeDescription {
        NSAttributeDescription().named(name).type(.stringAttributeType)
    }

    static func dateNamed(_ name: String) -> NSAttributeDescription {
        NSAttributeDescription().named(name).type(.dateAttributeType)
    }

    func named(_ name: String) -> Self {
        self.name = name
        return self
    }

    func optional(_ optional: Bool = true) -> NSAttributeDescription {
        self.isOptional = optional
        return self
    }

    func type(_ attributeType: NSAttributeType) -> NSAttributeDescription {
        self.attributeType = attributeType
        return self
    }
}

extension Collection where Element: Hashable {
    var mostPopulousElement: Element? {
        if count < 2 {
            return first
        } else {
            return reduce(into: [Element: Int]()) { counter, element in
                counter[element, default: 0] += 1
            }
            .sorted(usingKey: \.value, by: >).first?
            .key
        }
    }
}

extension CBSenderCorrelationController {
    public static var debug = false
}

prefix operator ~

@_transparent
private prefix func ~ (_ expression: @autoclosure () -> Void) {
    if _fastPath(!CBSenderCorrelationController.debug) {
        return
    }
    expression()
}

/// Tracks the correlation of different sender IDs to a single, unique identity representing an Apple ID
public class CBSenderCorrelationController {
    private class Stack {
        let log = Logger(label: "CBSenderCorrelationController.Stack")
        static let stack = Stack()

        static func storeURL() throws -> URL {
            try FileManager.default.barcelonaDirectory().appendingPathComponent("correlation2.sqlite")
        }

        static func oldStoreURL() throws -> URL {
            try FileManager.default.barcelonaDirectory().appendingPathComponent("correlation.db")
        }

        struct Correlation: Codable {
            var correl_id: String
            var sender_id: String
            var last_seen: Date
            var first_seen: Date

            init(row: Row) {
                correl_id = row["correl_id"]
                sender_id = row["sender_id"]
                last_seen = row["last_seen"]
                first_seen = row["first_seen"]
            }
        }

        let storeURL = try! storeURL()
        let pool: DatabasePool

        init() {
            pool = try! DatabasePool(path: storeURL.path)

            var migrator = DatabaseMigrator()
            migrator.registerMigration("v1") { database in
                try database.create(table: "correlation") { table in
                    table.column("correl_id", .text).indexed()
                    table.column("sender_id", .text).unique(onConflict: .rollback).indexed()
                    table.column("last_seen", .date).defaults(sql: "CURRENT_TIMESTAMP")
                    table.column("first_seen", .date).defaults(sql: "CURRENT_TIMESTAMP")
                }
            }

            try! migrator.migrate(pool)

            var migratedDatabase: Bool {
                get {
                    UserDefaults.standard.bool(forKey: "migrated-database")
                }
                set {
                    UserDefaults.standard.set(newValue, forKey: "migrated-database")
                }
            }

            if let oldURL = try? Self.oldStoreURL(), FileManager.default.fileExists(atPath: oldURL.path),
                !migratedDatabase
            {
                log.info("Found old correlation database, attempting to import", source: "Correlation")
                do {
                    let queue = try DatabaseQueue(path: oldURL.path)
                    try queue.read { database in
                        var stmt = try database.makeSelectStatement(
                            sql: "SELECT identifier FROM grdb_migrations where identifier = 'v4';"
                        )
                        guard try String.fetchOne(stmt) != nil else {
                            log.warning(
                                "Correlation database was not upgraded to v4, I will not be migrating it.",
                                source: "Correlation"
                            )
                            return
                        }
                        stmt = try database.makeSelectStatement(
                            sql: "SELECT correlation_identifier, sender_id FROM correlation"
                        )
                        let cursor = try Row.fetchCursor(stmt)
                        try self.pool.write { database2 in
                            while let row = try cursor.next() {
                                let correl_id: String = row["correlation_identifier"]
                                guard UUID(uuidString: correl_id) != nil else {
                                    continue
                                }
                                let sender_id: String = row["sender_id"]
                                log.debug("Importing correlation of \(sender_id)/\(correl_id)", source: "Correlation")
                                try database2.execute(
                                    literal: """
                                        INSERT OR IGNORE INTO correlation (correl_id, sender_id) VALUES (\(correl_id), \(sender_id))
                                        """
                                )
                            }
                        }
                        log.info("Migrated correlation database!", source: "Correlation")
                        try FileManager.default.removeItem(at: oldURL)
                    }
                    migratedDatabase = true
                } catch {
                    log.error(
                        "Failed to migrate old correlation database: \((error as NSError).debugDescription)",
                        source: "Correlation"
                    )
                }
            }
        }

        private func read<T>(_ callback: @escaping (Database) throws -> T) -> Promise<T> {
            Promise { resolve, reject in
                pool.asyncRead { result in
                    do {
                        let result = try result.get()
                        try resolve(callback(result))
                    } catch {
                        reject(error)
                    }
                }
            }
            .resolving(on: CBSenderCorrelationController.queue)
        }

        func correlations(forSender sender: String) -> Promise<[Correlation]> {
            read { result in
                let stmt = try result.makeSelectStatement(
                    sql:
                        """
                        SELECT o.*
                        FROM correlation c
                        INNER JOIN correlation o ON o.correl_id = c.correl_id
                        WHERE c.sender_id = $1
                        """
                )
                try stmt.setArguments([sender])
                let rows = try Row.fetchCursor(stmt)
                return try Array(rows.map(Correlation.init(row:)))
            }
        }

        func correlationID(for sender: String) -> Promise<String?> {
            read { result in
                let stmt = try result.makeSelectStatement(
                    sql:
                        """
                        SELECT c.correl_id
                        FROM correlation c
                        WHERE c.sender_id = $1
                        """
                )
                try stmt.setArguments([sender])
                let row = try Row.fetchOne(stmt)
                return row?["correl_id"]
            }
        }

        func correlationIDs(for senders: [String]) -> Promise<[String: String]> {
            read { result in
                let req: SQLRequest<Row> = """
                    SELECT c.sender_id, c.correl_id
                    FROM correlation c
                    WHERE c.sender_id IN \(senders)
                    """
                let cursor = try req.fetchCursor(result)
                return try Dictionary(uniqueKeysWithValues: Array(cursor.map { ($0["sender_id"], $0["correl_id"]) }))
            }
        }

        func allCorrelations() -> Promise<[Correlation]> {
            read { result in
                let stmt = try result.makeSelectStatement(
                    sql:
                        """
                        SELECT *
                        FROM correlation c
                        """
                )
                let rows = try Row.fetchCursor(stmt)
                return try Array(rows.map(Correlation.init(row:)))
            }
        }

        func witness(correlationID: String, senderID: String) -> Promise<Void> {
            Promise { resolve, reject in
                pool.asyncWrite(
                    { database in
                        try database.execute(
                            sql:
                                """
                                INSERT INTO correlation(correl_id, sender_id) VALUES($1, $2)
                                    ON CONFLICT(sender_id)
                                        DO UPDATE SET correl_id=excluded.correl_id, sender_id=excluded.sender_id, last_seen=CURRENT_TIMESTAMP
                                """,
                            arguments: [correlationID, senderID]
                        )
                    },
                    completion: { $1.promise.then(resolve).catch(reject) }
                )
            }
            .resolving(on: CBSenderCorrelationController.queue)
        }
    }

    public static let shared = CBSenderCorrelationController()

    public init() {
        reset()
    }

    private let log = Logger(label: "CBSenderCorrelation")
    private static let queue = DispatchQueue(label: "CBSenderCorrelation")

    /// this dictionary tracks the latest optionality to avoid redundant db hits for correlation IDs that we don't have
    private var senderIDToCorrelationID: [String: String?] = [:]
    private let senderIDToCorrelationIDLock = NSRecursiveLock()

    /// Establish a correlation between a sender ID and a correlation ID
    public func correlate(senderID: String, correlationID: String) {
        let senderID = IDSDestination(uri: senderID).uri().prefixedURI ?? senderID
        if senderID == correlationID {
            ~log.debug(
                "Ignoring equal self-referencing ID for \(senderID) (this means they are using a temporary registration and there's nothing to correlate against)"
            )
            return
        }
        senderIDToCorrelationIDLock.withLock {
            switch senderIDToCorrelationID[senderID] {
            case .none, .some(.none):
                senderIDToCorrelationID[senderID] = correlationID
                DispatchQueue.global()
                    .async { _ = Stack.stack.witness(correlationID: correlationID, senderID: senderID) }
            default:
                break
            }
        }
    }

    private func cachedCorrelation(for destination: String) -> String?? {
        if let override = CBCorrelationOverrideController.shared.override(for: destination) {
            return .some(override)
        }
        return senderIDToCorrelationIDLock.withLock {
            senderIDToCorrelationID[destination]
        }
    }

    private func loadCachedCorrelations(senderIDs: [String], hitDatabase: Bool = true) -> [String: String?] {
        var loadedCorrelations = Dictionary(uniqueKeysWithValues: senderIDs.map { ($0, cachedCorrelation(for: $0)) })
            .compactMapValues { $0 }
        let missingCorrelations = senderIDs.filter { loadedCorrelations[$0] == nil }
        // no missing correlations, fast return
        if missingCorrelations.isEmpty || !hitDatabase {
            return loadedCorrelations
        }
        let semaphore = DispatchSemaphore(value: 1)
        // load from database
        try? Stack.stack.correlationIDs(for: missingCorrelations)
            .always { outcome in
                if case .success(let correlations) = outcome {
                    for (senderID, correlationID) in correlations {
                        loadedCorrelations[senderID] = correlationID
                    }
                }
                semaphore.signal()
            }
            .resolving(on: DispatchQueue.global()).wait(upTo: .distantFuture)
        // lock for the entire enumeration
        senderIDToCorrelationIDLock.withLock {
            // store the database results
            for missingCorrelation in missingCorrelations {
                senderIDToCorrelationID[missingCorrelation] = loadedCorrelations[missingCorrelation]
            }
        }
        return loadedCorrelations
    }

    private func retrieveCorrelations(senderIDs: [String]) -> Promise<[String: String]> {
        Promise { resolve in
            var correlations: [String: String] = [:]
            // we will only ever lookup IDs we have imessaged with at some point
            let senderIDs = senderIDs.filter {
                IMHandleRegistrar.sharedInstance().getIMHandles(forID: $0.fastDroppingURIPrefix)?
                    .contains(where: { $0.service == .iMessage() }) ?? false
            }
            if senderIDs.isEmpty {
                resolve([:])
                ~log.debug("No senders to query after filter, stop here")
                return
            }
            IDSIDQueryController.sharedInstance()
                .currentRemoteDevices(
                    for: senderIDs.compactMap(IDSDestination.init(uri:)),
                    service: "com.apple.madrid",
                    listenerID: "com.ericrabil.listener",
                    queue: CBSenderCorrelationController.queue
                ) { results in
                    if let results = results {
                        for (senderID, endpoints) in results {
                            for endpoint in endpoints {
                                if let correlationID = endpoint.senderCorrelationIdentifier {
                                    self.correlate(senderID: senderID, correlationID: correlationID)
                                    if let anonymizedID = endpoint.anonymizedSenderID {
                                        self.log.debug("Anonymized sender ID for \(senderID) is \(anonymizedID)")
                                    }
                                    if correlationID == senderID {
                                        self.log.debug(
                                            "Correlation ID is equal to the sender ID? \(senderID) == \(correlationID)"
                                        )
                                        continue
                                    }
                                    self.log.info(
                                        "IDS says the correlation identifier for \(senderID) is \(correlationID)"
                                    )
                                    correlations[senderID] = correlationID
                                    break
                                } else {
                                    ~self.log.debug("\(senderID) has no correlationID")
                                }
                            }
                        }
                    } else {
                        ~self.log.debug("IDSIDQueryController returned no results for ID query, confused. \(senderIDs)")
                    }
                    resolve(correlations)
                }
        }
        .resolving(on: CBSenderCorrelationController.queue)
    }

    private func retrieveCorrelationsAndWait(
        senderIDs: [String],
        upTo time: DispatchTime = .now().advanced(by: .seconds(1))
    ) -> [String: String] {
        (try? retrieveCorrelations(senderIDs: senderIDs).wait(upTo: time)) ?? [:]
    }

    /// Determines the correlation ID for a set of senders assumed to be the same person
    public func correlate(sameSenders senders: [String], offline: Bool = false, hitDatabase: Bool = true) -> String? {
        // no-op
        if senders.isEmpty || !CBFeatureFlags.correlateChats {
            return nil
        }
        // get all persisted correlation identifiers
        let cachedCorrelations = loadCachedCorrelations(senderIDs: senders, hitDatabase: hitDatabase)
        if cachedCorrelations.count == senders.count {
            // all correlations are stored
            ~log.debug("Cache hit when querying \(senders.count) senders, returning immediately")
            return cachedCorrelations.values.mostPopulousElement ?? nil
        } else if case .some(.some(let mostPopulousCorrelationID)) = cachedCorrelations.values.mostPopulousElement {
            // some correlations are stored, but not all
            for sender in senders {
                if cachedCorrelations[sender] == nil {
                    // this sender has no correlation, set it to the correlation ID with the highest count
                    ~log.debug("Cloning correlation of \(mostPopulousCorrelationID) to \(sender)")
                    correlate(senderID: sender, correlationID: mostPopulousCorrelationID)
                }
            }
            return mostPopulousCorrelationID
        } else if !offline {
            // no correlations!
            let correlations = retrieveCorrelationsAndWait(senderIDs: senders)
            if correlations.isEmpty {
                senderIDToCorrelationIDLock.withLock {
                    // there's truly no correlations, set caches to nil and return
                    for sender in senders {
                        ~log.debug("\(sender) has no correlation ID, caching a nil value")
                        senderIDToCorrelationID[sender] = .some(.none)
                    }
                }
                return nil
            } else {
                // store to the database and return
                let mostPopulousCorrelationID = correlations.values.mostPopulousElement!
                for sender in senders {
                    if correlations[sender] == nil {
                        // this sender has no correlation, set it to the correlation ID with the highest count
                        ~log.debug("Cloning correlation of \(mostPopulousCorrelationID) to \(sender)")
                        correlate(senderID: sender, correlationID: mostPopulousCorrelationID)
                    }
                }
                return mostPopulousCorrelationID
            }
        } else {
            return nil
        }
    }

    /// For an array of senders, prewarms their correlation data.
    public func prewarm(senders: [String]) -> Promise<Void> {
        // only take senders that haven't been queried
        let senders = senderIDToCorrelationIDLock.withLock {
            senders.filter {
                senderIDToCorrelationID[$0] == .none
            }
        }
        guard !senders.isEmpty else {
            return .success(())
        }
        return retrieveCorrelations(senderIDs: senders)
            .then { [unowned self] correlations in
                senderIDToCorrelationIDLock.withLock {
                    for sender in senders {
                        senderIDToCorrelationID[sender] = .some(correlations[sender])
                    }
                }
            }
    }

    public func reset() {
        let allCorrelations = try! Stack.stack.allCorrelations().wait(upTo: .distantFuture)
        senderIDToCorrelationIDLock.withLock {
            for correlation in allCorrelations {
                senderIDToCorrelationID[correlation.sender_id] = correlation.correl_id
            }
        }
    }

    /// Queries the correlation identifier for a given sender ID, if it is known
    public func correlate(senderID: String) -> String? {
        correlate(sameSenders: [senderID], offline: true)
    }

    public func siblingSenders(for senderID: String) -> [String] {
        do {
            return try Stack.stack.correlations(forSender: senderID).map(\.sender_id).wait(upTo: .distantFuture)
        } catch {
            return []
        }
    }
}

public protocol CBSenderTargetable {
    var senderDestination: IDSDestination? { get }
}

extension CBSenderTargetable {
    public var senderCorrelationID: String? {
        senderDestination?.correlationID
    }
}

extension IDSURI {
    public var correlationID: String? {
        prefixedURI.flatMap(CBSenderCorrelationController.shared.correlate(senderID:))
    }
}

extension IDSDestination {
    public var correlationID: String? {
        guard CBFeatureFlags.correlateChats else {
            return nil
        }
        return uri().correlationID
    }
}

extension IDSDestination {
    fileprivate convenience init?(imID: String) {
        if imID.hasPrefix("e:") {
            self.init(uri: String(imID.suffix(from: imID.index(imID.startIndex, offsetBy: 2))))
        } else {
            self.init(uri: imID)
        }
    }
}

extension IMHandle: CBSenderTargetable {
    public var senderDestination: IDSDestination? {
        IDSDestination(imID: id)
    }
}

extension IMMessage: CBSenderTargetable {
    public var senderDestination: IDSDestination? {
        sender?.senderDestination ?? senderID.flatMap(IDSDestination.init(imID:))
    }
}

extension IMMessageItem: CBSenderTargetable {
    public var senderDestination: IDSDestination? {
        senderID.flatMap(IDSDestination.init(imID:))
    }
}

extension CBMessageStatusChange: CBSenderTargetable {
    public var senderDestination: IDSDestination? {
        sender.flatMap(IDSDestination.init(imID:))
    }
}

extension Message: CBSenderTargetable {
    public var senderDestination: IDSDestination? {
        sender.flatMap(IDSDestination.init(imID:))
    }
}

extension IMChat {
    /// Returns other chats with the same sender correlation ID
    public var siblings: [IMChat] {
        // This is a band-aid for now. Since this doesn't try to merge
        // SMS<->iMessage conversations, this flag (`correlateChats`)
        // controls chat merging along with correlating.
        // TODO: Actually separate them out and fix correlation lol
        if isGroup || !CBFeatureFlags.correlateChats {
            return [self]
        } else {
            var siblings =
                recipient?.senderDestination
                .map { destination in
                    CBSenderCorrelationController.shared.siblingSenders(for: destination.uri().prefixedURI)
                }
                .map { senders -> [IMChat] in
                    senders.compactMap { senderID in
                        IMAccountController.shared.iMessageAccount?.imHandle(withID: senderID.droppingURIPrefix)
                    }
                    .compactMap(IMChatRegistry.shared.chat(for:))
                } ?? []
            if !siblings.contains(self) {
                siblings.insert(self, at: 0)
            }
            #if DEBUG
            log.debug("Siblings for \(self.id) are \(siblings.map(\.debugDescription))", source: "Correlation")
            #endif
            return siblings
        }
    }
}

// MARK: - Overrides

public class CBCorrelationOverrideController {
    public static let shared = CBCorrelationOverrideController()

    private let suite = UserDefaults(suiteName: "com.ericrabil.barcelona.correlation-override")!

    public func override(for destination: String) -> String? {
        suite.string(forKey: destination)
    }

    public func store(_ override: String, for destination: String) {
        suite.set(override, forKey: destination)
    }

    public func clear(_ destination: String) {
        suite.removeObject(forKey: destination)
    }
}

extension CBCorrelationOverrideController {
    var allOverrides: [String: String] {
        suite.dictionaryRepresentation()
            .compactMapValues {
                $0 as? String
            }
    }
}

// MARK: - CLI

public class CBCorrelationCommands: CommandGroup {
    public let name: String = "correlation"
    public let shortDescription: String = "interact with the correlation subsystem"

    public init() {

    }

    public class Resolve: Command {
        public let name: String = "resolve"
        public let shortDescription: String = "resolve the current correlation identifier for a given sender"

        @Param public var sender: String

        public func execute() throws {
            print(CBSenderCorrelationController.shared.correlate(senderID: sender))
        }
    }

    public class Overrides: CommandGroup {
        public let name: String = "overrides"
        public let shortDescription: String = "manage correlation overrides"

        public class ShowOverrides: Command {
            public let name: String = "show"
            public let shortDescription: String = "show all stored overrides"

            public func execute() throws {
                print(CBCorrelationOverrideController.shared.allOverrides.debugDescription)
            }
        }

        public class ClearOverrides: Command {
            public let name: String = "clear"
            public let shortDescription: String = "clear overrides from defaults"

            @CollectedParam
            public var destinations: [String]

            public func execute() throws {
                for destination in destinations {
                    CBCorrelationOverrideController.shared.clear(destination)
                }
            }
        }

        public class InsertOverride: Command {
            public let name: String = "insert"
            public let shortDescription: String = "insert an override into defaults"

            @Param public var destination: String
            @Param public var override: String

            public func execute() throws {
                CBCorrelationOverrideController.shared.store(override, for: destination)
            }
        }

        public let children: [Routable] = [ShowOverrides(), ClearOverrides(), InsertOverride()]
    }

    public let children: [Routable] = [Overrides(), Resolve()]
}
