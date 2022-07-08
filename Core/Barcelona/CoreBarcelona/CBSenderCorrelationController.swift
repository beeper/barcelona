//
//  CBSenderCorrelationController.swift
//  Barcelona
//
//  Created by Eric Rabil on 3/12/22.
//

import Foundation
import GRDB
import IDS
import IMCore
import Swog

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
}

internal extension String {
    var droppingURIPrefix: String {
        IDSDestination(uri: self).uri().unprefixedURI
    }
}

extension IMChat: Identifiable {
    public var id: String {
        chatIdentifier
    }
}

@propertyWrapper
public struct Atomic<T> {
    private var _wrappedValue: T!
    private let lock = NSRecursiveLock()
    
    public var wrappedValue: T {
        _read {
            lock.lock()
            yield _wrappedValue
            lock.unlock()
        }
        _modify {
            lock.lock()
            yield &_wrappedValue
            lock.unlock()
        }
    }
    
    public init() {
        
    }
}

extension Atomic: Encodable where T: Encodable {
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension Atomic: Decodable where T: Decodable {
    public init(from decoder: Decoder) throws {
        _wrappedValue = try T(from: decoder)
    }
}

/// Tracks the correlation of different sender IDs to a single, unique identity representing an Apple ID
public class CBSenderCorrelationController {
    public class Correlation: Codable, Hashable, FetchableRecord, PersistableRecord {
        @Atomic public fileprivate(set) var ROWID: Int64
        public fileprivate(set) var correl_id: String
        public fileprivate(set) var sender_id: String
        @Atomic public fileprivate(set) var first_seen: Date
        @Atomic public fileprivate(set) var last_seen: Date
        
        public static func == (lhs: Correlation, rhs: Correlation) -> Bool {
            lhs.correl_id == rhs.correl_id && lhs.sender_id == rhs.sender_id
        }
        
        public func hash(into hasher: inout Hasher) {
            correl_id.hash(into: &hasher)
            sender_id.hash(into: &hasher)
        }
        
        init(correl_id: String, sender_id: String, first_seen: Date = Date(), last_seen: Date = Date()) {
            self.correl_id = correl_id
            self.sender_id = sender_id
            self.ROWID = -1
            self.first_seen = first_seen
            self.last_seen = last_seen
        }
        
        enum Columns {
            static let ROWID = Column(CodingKeys.ROWID)
            static let correl_id = Column(CodingKeys.correl_id)
            static let sender_id = Column(CodingKeys.sender_id)
            static let first_seen = Column(CodingKeys.first_seen)
            static let last_seen = Column(CodingKeys.last_seen)
        }
    }
    
    private class OldCorrelation: Codable, FetchableRecord, PersistableRecord {
        var ROWID: Int64
        var correlation_identifier: String
        var sender_id: String
        var pinned: Bool?
        
        enum Columns {
            static let ROWID = Column(CodingKeys.ROWID)
            static let correlation_identifier = Column(CodingKeys.correlation_identifier)
            static let sender_id = Column(CodingKeys.sender_id)
            static let pinned = Column(CodingKeys.pinned)
        }
    }
    
    private class CBSenderCorrelationPersistence {
        
        static let databasePath: String = ProcessInfo.processInfo.environment["CBSenderCorrelationDB"] ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("/Library/Barcelona/correlation.db").path
        static let databaseFolder = URL(fileURLWithPath: databasePath).deletingLastPathComponent().path
        
        static let log = Logger(category: "CBSenderCorrelationDB")
        let log = CBSenderCorrelationPersistence.log
        let dbQueue: DatabasePool
        
        static let migrator: DatabaseMigrator = {
            var migrator = DatabaseMigrator()
            
            migrator.registerMigration("v1") { database in
                try database.create(table: "correlation") { table in
                    table.autoIncrementedPrimaryKey("ROWID")
                    table.column("correlation_identifier", .text).notNull()
                    table.column("sender_id", .text).notNull().unique(onConflict: .replace)
                }
                try database.create(index: "idx_correlation_identifier", on: "correlation", columns: ["correlation_identifier"])
                try database.create(index: "idx_sender_id", on: "correlation", columns: ["sender_id"])
            }
            
            migrator.registerMigration("v2") { database in
                try database.alter(table: "correlation") { table in
                    table.add(column: "pinned", .boolean)
                }
                try database.create(index: "idx_pinned_correlations", on: "correlation", columns: ["pinned"], condition: Column("pinned") == true)
            }
            
            migrator.registerMigration("v3") { database in
                try database.drop(index: "idx_pinned_correlations")
                try database.create(index: "idx_pinned_correlations", on: "correlation", columns: ["correlation_identifier","pinned"], unique: true, ifNotExists: false, condition: Column("pinned") == true)
            }
            
            migrator.registerMigration("v4") { database in
                var correlations = try OldCorrelation.fetchAll(database)
                correlations = correlations.filter { correlation in
                    UUID(uuidString: correlation.correlation_identifier) == nil
                }
                let correlationIdentfiersToRemove = correlations.map(\.correlation_identifier)
                try OldCorrelation.filter(correlationIdentfiersToRemove.contains(OldCorrelation.Columns.correlation_identifier)).deleteAll(database)
            }
            
            migrator.registerMigration("v5") { database in
                try database.create(table: "new_correlation") { table in
                    table.autoIncrementedPrimaryKey("ROWID")
                    table.column("correl_id", .text).indexed().notNull()
                    table.column("sender_id", .text).indexed().notNull().unique(onConflict: .replace)
                    table.column("first_seen", .datetime).defaults(sql: "CURRENT_TIMESTAMP")
                    table.column("last_seen", .datetime).defaults(sql: "CURRENT_TIMESTAMP")
                }
                try database.execute(sql:
                                        """
                                        INSERT INTO new_correlation (correl_id, sender_id)
                                        SELECT correlation_identifier, sender_id
                                        FROM correlation
                                        """)
                try database.drop(table: "correlation")
                try database.rename(table: "new_correlation", to: "correlation")
            }
            
            return migrator
        }()
        
        static let shared: CBSenderCorrelationPersistence? = {
            do {
                return try CBSenderCorrelationPersistence()
            } catch {
                log.fault("Couldn't open database at \(databasePath): \(String(describing: error))")
                return nil
            }
        }()
        
        private static let queue = DispatchQueue(label: "CBSenderCorrelationPersistence", attributes: .concurrent, autoreleaseFrequency: .workItem)
        private let config: Configuration = {
            var config = Configuration()
            config.targetQueue = queue
            config.qos = .userInitiated
            config.label = "CBSenderCorrelationPersistence"
            return config
        }()
        
        init() throws {
            try FileManager.default.createDirectory(atPath: CBSenderCorrelationPersistence.databaseFolder, withIntermediateDirectories: true, attributes: nil)
            dbQueue = try DatabasePool(path: CBSenderCorrelationPersistence.databasePath, configuration: config)
            try CBSenderCorrelationPersistence.migrator.migrate(dbQueue)
        }
        
        @discardableResult
        func correlate(senderID: String, correlationID: String) -> Promise<Correlation?> {
            Promise { resolve, reject in
                dbQueue.asyncWrite({ db in
                    try Correlation.fetchOne(db, sql:
                                """
                                INSERT INTO correlation (sender_id, correl_id)
                                VALUES ($1, $2)
                                ON CONFLICT(sender_id)
                                    DO
                                        UPDATE SET last_seen=CURRENT_TIMESTAMP
                                    WHERE correl_id=excluded.correl_id
                                RETURNING *
                                """, arguments: [senderID, correlationID])
                }, completion: { $1.promise.then(resolve).catch(reject) })
            }
        }
        
        func correlate(senderID: String) -> Promise<[Correlation]> {
            Promise { resolve, reject in
                dbQueue.asyncRead { result in
                    result.promise.then { db in
                        try Correlation.fetchAll(db, sql:
                                """
                                SELECT o.*
                                FROM correlation c
                                INNER JOIN correlation o ON o.correlation_identifier = c.correlation_identifier
                                WHERE c.sender_id = $1
                                """, arguments: [senderID])
                    }.then(resolve).catch(reject)
                }
            }
        }
        
        func correlateASAP(senderID: String) -> [Correlation] {
            (try? dbQueue.read { db in
                try Correlation.fetchAll(db, sql:
                        """
                        SELECT o.*
                        FROM correlation c
                        INNER JOIN correlation o ON o.correl_id = c.correl_id
                        WHERE c.sender_id = $1
                        """, arguments: [senderID])
            }) ?? []
        }
    }
    
    public static let shared = CBSenderCorrelationController()
    
    private let log = Logger(category: "CBSenderCorrelation")
    private let queue = DispatchQueue(label: "CBSenderCorrelation")
    
    /// A dictionary mapping sender IDs to a correlation ID that uniquely identifiers all sender IDs belonging to a specific person
    private var correlations: [String: Correlation?] = [:]
    /// A dictionary mapping correlation IDs to all known sender IDs
    private var reverseCorrelations: [String: Set<Correlation>] = [:]
    
    private func internalizeOnQueue(_ correlation: Correlation?, toRuntimeCorrelation runtimeCorrelation: Correlation) {
        if let correlation = correlation {
            runtimeCorrelation.ROWID = correlation.ROWID
            runtimeCorrelation.first_seen = correlation.first_seen
            runtimeCorrelation.last_seen = correlation.last_seen
        } else {
            if case .some(.some(let correlation)) = correlations[runtimeCorrelation.sender_id], correlation === runtimeCorrelation {
                correlations.removeValue(forKey: runtimeCorrelation.sender_id)
            }
            reverseCorrelations[runtimeCorrelation.correl_id]?.remove(runtimeCorrelation)
        }
    }
    
    private func internalizePendingCorrelation(_ promise: Promise<Correlation?>?, runtimeCorrelation: Correlation) {
        promise?.resolve(on: queue).always { result in
            switch result {
            case .success(let correlation):
                self.internalizeOnQueue(correlation, toRuntimeCorrelation: runtimeCorrelation)
            case .failure:
                self.internalizeOnQueue(nil, toRuntimeCorrelation: runtimeCorrelation)
            }
        }
    }
    
    private func persist(_ runtimeCorrelation: Correlation) {
        internalizePendingCorrelation(
            CBSenderCorrelationPersistence.shared?.correlate(senderID: runtimeCorrelation.sender_id, correlationID: runtimeCorrelation.correl_id),
            runtimeCorrelation: runtimeCorrelation
        )
    }
    
    private func cache(senderID: String, correlationID: String) {
        queue.sync {
            if case .some(.some(let runtimeCorrelation)) = correlations[senderID], runtimeCorrelation.correl_id == correlationID {
                runtimeCorrelation.last_seen = Date()
                persist(runtimeCorrelation)
                return
            }
            if case .some(.some(let oldCorrelation)) = correlations.removeValue(forKey: senderID) {
                reverseCorrelations[oldCorrelation.correl_id]?.remove(oldCorrelation)
            }
            let runtimeCorrelation = Correlation(correl_id: correlationID, sender_id: senderID)
            correlations[senderID] = runtimeCorrelation
            reverseCorrelations[correlationID, default: Set()].insert(runtimeCorrelation)
            persist(runtimeCorrelation)
        }
    }
    
    /// Establish a correlation between a sender ID and a correlation ID
    public func correlate(senderID: String, correlationID: String) {
        *log.debug("Correlating \(senderID) to \(correlationID)")
        cache(senderID: senderID, correlationID: correlationID)
    }
    
    /// Query the correlation ID for the given sender ID
    public func correlate(senderID: String) -> String? {
        switch queue.sync(execute: { correlations[senderID] }) {
        case .some(.some(let runtimeCorrelation)):
            return runtimeCorrelation.correl_id
        case .some(.none):
            return nil
        case .none:
            break
        }
        guard let correlations = CBSenderCorrelationPersistence.shared?.correlateASAP(senderID: senderID), let correlID = correlations.first?.correl_id else {
            correlations[senderID] = .some(.none)
            return nil
        }
        queue.sync {
            self.reverseCorrelations[correlID] = Set(correlations)
            for correlation in correlations {
                if case .some(.some(let existing)) = self.correlations[correlation.sender_id], existing.databaseEquals(correlation) {
                    continue
                }
                self.correlations[correlation.sender_id] = correlation
            }
        }
        return correlID
    }
    
    /// Query the correlation ID for the given sender ID, adding the URI scheme if it is missing
    public func correlate(fuzzySenderID: String) -> String? {
        correlate(senderID: IDSDestination(uri: fuzzySenderID).uri().prefixedURI)
    }
}
