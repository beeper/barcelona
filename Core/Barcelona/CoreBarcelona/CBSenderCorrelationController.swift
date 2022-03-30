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
    
    /// The GUID that sticks to a specific sender handle from a pool of correlated sender IDs, creates a stable identifier to be used for the duration of the local machines iMessage
    var senderCorrelatableGUID: String {
        if isGroup {
            return guid
        }
        return guidPrefix + CBSenderCorrelationController.shared.externalIdentifier(senderID: recipient.id)
    }
}


extension IMChat: Identifiable {
    public var id: String {
        if CBFeatureFlags.preferCorrelationIdentifiers {
            return CBSenderCorrelationController.shared.externalIdentifier(senderID: recipient.id)
        } else {
            return chatIdentifier
        }
    }
}

extension DatabaseWriter {
    func execute(sql: String, arguments: StatementArguments = StatementArguments(), _ callback: @escaping (Database, Result<(), Error>) -> ()) {
        asyncWrite({ database in
            try database.execute(sql: sql, arguments: arguments)
        }, completion: callback)
    }
}

protocol _DatabaseWriteElement {
    
}

@resultBuilder
struct DatabaseWrite: _DatabaseWriteElement {
    var databaseCallbacks: [WriteAction] = []
    var successCallbacks: [OnSuccess] = []
    var failureCallbacks: [OnFailure] = []
    
    init() {
        
    }
    
    init(@DatabaseWrite writer: () -> DatabaseWrite) {
        self = writer()
    }
    
    static func buildBlock(_ components: _DatabaseWriteElement...) -> DatabaseWrite {
        var writer = DatabaseWrite()
        for component in components {
            switch component {
            case let database as WriteAction:
                writer.databaseCallbacks.append(database)
            case let success as OnSuccess:
                writer.successCallbacks.append(success)
            case let failure as OnFailure:
                writer.failureCallbacks.append(failure)
            case let write as DatabaseWrite:
                writer.databaseCallbacks.append(contentsOf: write.databaseCallbacks)
                writer.successCallbacks.append(contentsOf: write.successCallbacks)
                writer.failureCallbacks.append(contentsOf: write.failureCallbacks)
            default:
                continue
            }
        }
        return writer
    }
    
    func run(_ dbQueue: DatabaseWriter) {
        dbQueue.asyncWrite({ [databaseCallbacks] database in
            for databaseCallback in databaseCallbacks {
                try databaseCallback.imp(database)
            }
        }, completion: { [successCallbacks, failureCallbacks] database, result in
            switch result {
            case .success:
                for successCallback in successCallbacks {
                    successCallback.imp()
                }
            case .failure(let error):
                for failureCallback in failureCallbacks {
                    failureCallback.imp(error)
                }
            }
        })
    }
}

struct WriteAction: _DatabaseWriteElement {
    typealias Imp = (Database) throws -> ()
    var imp: Imp
    
    init(_ actions: [WriteAction]) {
        imp = { database in
            for action in actions {
                try action.imp(database)
            }
        }
    }
    
    init(_ callback: @escaping Imp) {
        self.imp = callback
    }
}

struct OnSuccess: _DatabaseWriteElement {
    typealias Imp = () -> ()
    var imp: Imp
    
    init(_ callback: @escaping Imp) {
        self.imp = callback
    }
    
    init(_ log: Logger, message callback: @escaping @autoclosure () -> BackportedOSLogMessage) {
        self.imp = { [log, callback] in
            log.info(callback())
        }
    }
}

struct OnFailure: _DatabaseWriteElement {
    typealias Imp = (Error) -> ()
    var imp: Imp
    
    init(_ callback: @escaping Imp) {
        self.imp = callback
    }
    
    init(_ log: Logger, message callback: @escaping @autoclosure () -> BackportedOSLogMessage) {
        self.imp = { [log, callback] error in
            var interp = callback().interpolation
            interp.appendLiteral(": ")
            interp.appendInterpolation(String(describing: error))
            let message = BackportedOSLogMessage(stringInterpolation: interp)
            log.fault(message)
        }
    }
}

/// Tracks the correlation of different sender IDs to a single, unique identity representing an Apple ID
public class CBSenderCorrelationController {
    private class CBSenderCorrelationPersistence {
        class Correlation: Codable, FetchableRecord, PersistableRecord  {
            private(set) var ROWID: Int64
            private(set) var pinned: Bool
            private(set) var correlation_identifier: String
            private(set) var sender_id: String
            
            init(pinned: Bool, correlation_identifier: String, sender_id: String) {
                self.ROWID = -1
                self.pinned = pinned
                self.correlation_identifier = correlation_identifier
                self.sender_id = sender_id
            }
            
            enum Columns {
                static let ROWID = Column(CodingKeys.ROWID)
                static let pinned = Column(CodingKeys.pinned)
                static let correlation_identifier = Column(CodingKeys.correlation_identifier)
                static let sender_id = Column(CodingKeys.sender_id)
            }
            
            private static let log = Logger(category: "Correlation")
            private var log: Logger { Correlation.log }
            
            /// Synchronously loads all correlated sender IDs
            static func allSenderIDs(_ reader: DatabaseReader) -> [String] {
                do {
                    let senderIDs = try reader.read { database in
                        try String.fetchAll(database, sql: "SELECT sender_id FROM correlation")
                    }
                    log.debug("Loaded \(senderIDs.count) sender IDs from database")
                    return senderIDs
                } catch {
                    log.fault("Couldn't load sender IDs from database: \(String(describing: error))")
                    return []
                }
            }
            
            private static func _correlate(_ database: Database, identifier correlationID: String) throws -> Correlation? {
                try select(sql: "*").filter(Columns.correlation_identifier == correlationID && Columns.pinned == true).fetchOne(database)
            }
            
            /// Returns the pinned correlation for a given correlation identifier, or nil if none is pinned
            static func correlate(_ dbQueue: DatabaseReader, identifier correlationID: String) -> Correlation? {
                do {
                    return try dbQueue.read { database in
                        try _correlate(database, identifier: correlationID)
                    }
                } catch {
                    log.fault("Failed to lookup pinned correlation for \(correlationID, privacy: .private): \(String(describing: error))")
                    return nil
                }
            }
            
            /// Returns an existing pinned correlation from the given sender ID, if there are any correlations for this sender ID. Otherwise returns the sender ID.
            static func correlate(_ dbQueue: DatabaseReader & DatabaseWriter, senderID: String) -> String {
                do {
                    return try dbQueue.read { database in
                        if let correlation = try select(sql: "*").filter(Columns.sender_id == senderID).fetchOne(database) {
                            if correlation.pinned {
                                return senderID
                            }
                            if let correlation = try _correlate(database, identifier: correlation.correlation_identifier) {
                                return correlation.sender_id
                            }
                            correlate(dbQueue, identifier: correlation.correlation_identifier, sender: senderID, pinned: true)
                            return senderID
                        }
                        return senderID
                    }
                } catch {
                    log.fault("Failed to lookup pinned correlation for \(senderID, privacy: .private): \(String(describing: error))")
                    return senderID
                }
            }
            
            /// Persists a correlation identifier and alias relationship.
            /// Optionally, you can specify to pin this sender ID. Pinning this sender ID will overwrite any unpin any pre-existing sender ID
            static func correlate(_ dbQueue: DatabaseWriter, identifier correlationID: String, sender senderID: String, pinned: Bool = false) {
                DatabaseWrite {
                    // set any currently pinned sender that is not senderID to false
                    Queries.unpinAll(correlationID, except: senderID)
                    // insert/replace new correlation
                    Queries.save(correlationID, sender: senderID, pinned: pinned)
                    OnSuccess(log, message: "Persisted correlation of sender \(senderID, privacy: .private) and correl. \(correlationID, privacy: .private)")
                    OnFailure(log, message: "Failed to persist correlation of sender \(senderID, privacy: .private) and correl. \(correlationID, privacy: .private)")
                }.run(dbQueue)
            }
            
            /// Persists a set of correlation identifier/alias relationships, useful for backfilling or other bulk ingestion
            static func correlate(_ dbQueue: DatabaseWriter, correlations: [(identifier: String, sender: String, pinned: Bool)]) {
                DatabaseWrite {
                    Queries.save(correlations)
                    OnSuccess(log, message: "Persisted \(correlations.count) correlations")
                    OnFailure(log, message: "Failed to persist \(correlations.count)")
                }.run(dbQueue)
            }
            
            func set(_ dbQueue: DatabaseWriter, pinned: Bool) {
                let oldValue = self.pinned
                self.pinned = pinned
                DatabaseWrite {
                    Queries.setPinned(pinned, where: ROWID)
                    OnSuccess(log, message: "Set pinned = \(pinned) for correlation ID \(self.ROWID)")
                    OnFailure(log, message: "Failed to set pinned = \(pinned) for correlation ID \(self.ROWID)")
                    OnFailure { [weak self, pinned] _ in
                        if let self = self, self.pinned == pinned {
                            self.pinned = oldValue
                        }
                    }
                }.run(dbQueue)
            }
            
            struct Queries {
                static func unpinAll(_ correlationID: String, except senderID: String) -> WriteAction {
                    WriteAction { database in
                        try database.execute(sql: "UPDATE correlation SET pinned = false WHERE correlation_identifier = ? AND sender_id != ?", arguments: [correlationID, senderID])
                    }
                }
                
                static func setPinned(_ pinned: Bool, where ROWID: Int64) -> WriteAction {
                    WriteAction { database in
                        try database.execute(sql: "UPDATE correlation SET pinned = ? WHERE ROWID = ?", arguments: [pinned, ROWID])
                    }
                }
                
                static func save(_ identifier: String, sender: String, pinned: Bool) -> WriteAction {
                    WriteAction { database in
                        try database.execute(sql: "INSERT INTO correlation (correlation_identifier, sender_id, pinned) VALUES (?,?,?)", arguments: [identifier, sender, pinned])
                    }
                }
                
                static func save(_ correlations: [(identifier: String, sender: String, pinned: Bool)]) -> WriteAction {
                    WriteAction(correlations.map(save(_:sender:pinned:)))
                }
            }
        }
        
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
        
        var allSenderIDs: [String] {
            Correlation.allSenderIDs(dbQueue)
        }
        
        func correlate(senderID: String, correlationID: String) {
            Correlation.correlate(dbQueue, identifier: correlationID, sender: senderID)
        }
        
        func correlate(senderID: String) -> String? {
            do {
                let correlation = try dbQueue.read { database in
                    try Correlation.fetchOne(database, key: [
                        "sender_id": senderID
                    ])
                }
                return correlation?.correlation_identifier
            } catch {
                log.fault("Failed to lookup correlation identifier of \(senderID, privacy: .private): \(String(describing: error))")
                return nil
            }
        }
        
        /// Takes a dictionary of <URI, correlationID> and saves it to the database
        func save(correlations: [String: String]) {
            Correlation.correlate(dbQueue, correlations: correlations.map { senderID, correlationID in (correlationID, senderID, false) })
        }
        
        func correlate(correlationID: String) -> [String] {
            do {
                let correlations = try dbQueue.read { database in
                    try Correlation.fetchAll(database, sql: "SELECT * FROM correlation WHERE correlation_identifier = ?", arguments: [correlationID])
                }
                return correlations.map(\.sender_id)
            } catch {
                log.fault("Failed to lookup known sender IDs for correlation identifier \(correlationID): \(String(describing: error))")
                return []
            }
        }
        
        func pinned(senderFromSender sender: String) -> String {
            Correlation.correlate(dbQueue, senderID: sender)
        }
        
        func pin(correlationID: String, senderID: String) {
            Correlation.correlate(dbQueue, identifier: correlationID, sender: senderID, pinned: true)
        }
        
        func pin(senderID: String) {
            if let correlationID = correlate(senderID: senderID) {
                pin(correlationID: correlationID, senderID: senderID)
            }
        }
    }
    
    public static let shared = CBSenderCorrelationController()
    
    private let log = Logger(category: "CBSenderCorrelation")
    private let queue = DispatchQueue(label: "CBSenderCorrelation")
    
    /// A dictionary mapping sender IDs to a correlation ID that uniquely identifiers all sender IDs belonging to a specific person
    private var correlations: [String: String] = [:]
    /// A dictionary mapping correlation IDs to all known sender IDs
    private var reverseCorrelations: [String: Set<String>] = [:]
    
    /// Rehydrates cache of a correlation/sender relationship from database
    private func bulkLoad(senders: [String], correlationID: String) -> Set<String> {
        queue.sync {
            for senderID in senders {
                if let oldID = correlations.removeValue(forKey: senderID) {
                    reverseCorrelations[oldID]?.remove(senderID)
                }
                correlations[senderID] = correlationID
            }
            let senders = Set(senders)
            reverseCorrelations[correlationID] = senders
            return senders
        }
    }
    
    private func cache(senderID: String, correlationID: String) {
        queue.sync {
            if let oldID = correlations.removeValue(forKey: senderID) {
                reverseCorrelations[oldID]?.remove(senderID)
            }
            correlations[senderID] = correlationID
            reverseCorrelations[correlationID, default: Set()].insert(senderID)
        }
    }
    
    /// Establish a correlation between a sender ID and a correlation ID
    public func correlate(senderID: String, correlationID: String) {
        if let existingID = correlations[senderID], existingID == correlationID {
            // no need to cache or persist, its already correlated
            return
        }
        *log.debug("Correlating \(senderID) to \(correlationID)")
        cache(senderID: senderID, correlationID: correlationID)
        CBSenderCorrelationPersistence.shared?.correlate(senderID: senderID, correlationID: correlationID)
    }
    
    /// Queries the correlation identifier for a given sender ID, if it is known
    public func correlate(senderID: String) -> String? {
        if let correlationID = queue.sync(execute: { correlations[senderID] }) {
            // cache hit!
            return correlationID
        }
        if let correlationID = CBSenderCorrelationPersistence.shared?.correlate(senderID: senderID) {
            // store database correlation in cache and return
            cache(senderID: senderID, correlationID: correlationID)
            return correlationID
        }
        return nil
    }
    
    /// Queries all known sender IDs for a given correlation identifier
    public func correlate(correlationID: String) -> Set<String> {
        if let correlations = queue.sync(execute: { reverseCorrelations[correlationID] }) {
            return correlations
        }
        if let senders = CBSenderCorrelationPersistence.shared?.correlate(correlationID: correlationID) {
            return bulkLoad(senders: senders, correlationID: correlationID)
        }
        return Set()
    }
    
    public func externalIdentifier(senderID: String) -> String {
        if let pinnedIdentifier = CBSenderCorrelationPersistence.shared?.pinned(senderFromSender: senderID) {
            return pinnedIdentifier
        }
        if let correlationIdentifier = CBSenderCorrelationPersistence.shared?.correlate(senderID: senderID) {
            CBSenderCorrelationPersistence.shared?.pin(correlationID: correlationIdentifier, senderID: senderID)
        }
        return senderID
    }
    
    private var allKnownURIs: [String] {
        CBSenderCorrelationPersistence.shared?.allSenderIDs ?? Array(correlations.keys)
    }
    
    /// Of the given URIs, persists any URIs that are not already known
    public func correlate(uris: [String], callback: (() -> ())? = nil) {
        let allKnownURIs = allKnownURIs
        let allDestinations = uris.map(IDSDestination.init(uri:))
        let destinations = allDestinations.filter { !allKnownURIs.contains($0.uri().prefixedURI) }.prefix(10)
        if destinations.isEmpty {
            return
        }
        correlate(destinations: Array(destinations), callback: callback)
    }
    
    public func correlate(destinations: [IDSDestination], callback: (() -> ())? = nil) {
        IDSIDQueryController.sharedInstance().currentRemoteDevices(for: destinations, service: "com.apple.madrid", listenerID: "com.ericrabil.listener", queue: .global(qos: .userInitiated)) { results in
            if let results = results {
                let correlations = results.values.flatten().dictionary(keyedBy: \.uri.prefixedURI, valuedBy: \.senderCorrelationIdentifier)
                if let persistence = CBSenderCorrelationPersistence.shared {
                    persistence.save(correlations: correlations)
                } else {
                    // if the persistence system isnt working, just store in memory
                    for (correlationID, senders) in correlations.collectedDictionary(keyedBy: \.value, valuedBy: \.key) {
                        _ = self.bulkLoad(senders: senders, correlationID: correlationID)
                    }
                }
            }
            callback?()
        }
    }
    
    private class CBSenderCorrelationBackfillController {
        static let queue = DispatchQueue(label: "CBSenderCorrelationBackfill")
        static let log = Logger(category: "CBSenderCorrelationBackfill")
        var log: Logger { CBSenderCorrelationBackfillController.log }
        
        var destinations: Set<IDSDestination> = Set()
        
        init?() {
            guard CBSenderCorrelationPersistence.shared != nil else {
                // backfilling without a database is pointless and wasteful
                log.warn("Nilling out backfill controller, no backfill without a database")
                return nil
            }
            let allKnownURIs = CBSenderCorrelationController.shared.allKnownURIs
            let uris = IMAccountController.shared.iMessageAccount?.arrayOfAllIMHandles.map(\.id) ?? []
            let allDestinations = uris.map(IDSDestination.init(uri:))
            let destinations = allDestinations.filter { !allKnownURIs.contains($0.uri().prefixedURI) }
            if destinations.isEmpty {
                log.info("Nilling out backfill controller, there's no more URIs that need backfilling")
                return nil
            }
            self.destinations = Set(destinations)
        }
        
        deinit {
            pending?.cancel()
        }
        
        var isDone: Bool {
            destinations.isEmpty
        }
        
        private func doNext() {
            var batch: [IDSDestination] = []
            while batch.count < 10 && !destinations.isEmpty {
                batch.append(destinations.removeFirst())
            }
            log.info("Backfilling \(batch.count) uris")
            CBSenderCorrelationController.shared.correlate(destinations: batch, callback: run)
        }
        
        private var pending: DispatchSourceTimer?
        private let seconds = 60
        
        private func run() {
            if isDone {
                pending = nil
                log.info("Finished backfilling")
                return
            }
            let timer = DispatchSource.makeTimerSource(queue: CBSenderCorrelationBackfillController.queue)
            timer.setEventHandler(handler: doNext)
            timer.schedule(deadline: .now().advanced(by: .seconds(seconds)), leeway: .seconds(60))
            timer.resume()
            log.info("Next backfill batch running in \(self.seconds) seconds")
            pending = timer
        }
        
        func start() {
            if pending != nil, !isDone {
                return
            }
            run()
        }
    }
    
    private var backfillController: CBSenderCorrelationBackfillController?
    func backfill() {
        guard let backfillController = CBSenderCorrelationBackfillController() else {
            return
        }
        backfillController.start()
        self.backfillController = backfillController
    }
}
