//
//  Reader.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB
import Logging

extension Configuration {
    init(trace: TraceFunction?) {
        self.init()
        self.trace = trace
        maximumReaderCount = 25
        qos = .init(qosClass: .userInitiated, relativePriority: 9999)
    }
}

#if DB_LOGGING
private var dbConfiguration = Configuration { db in
    log.debug("Executing query: %@", db)
}
#else
private var dbConfiguration = Configuration(trace: nil)
#endif

let databasePool = try! DatabasePool(
    path: ("~/Library/Messages/chat.db" as NSString).expandingTildeInPath,
    configuration: dbConfiguration
)

/// Interface for reading the chat.db file.
///
/// DO NOT MAKE WRITES! THIS IS FOR READING ONLY!
// MARK: - I REPEAT DO NOT MAKE WRITES TO THE DATABASE DIRECTLY! THIS IS FOR READING ONLY!
public struct DBReader {
    internal var pool: DatabasePool

    public static let shared: DBReader = DBReader(pool: databasePool)

    private init(pool: DatabasePool = databasePool) {
        self.pool = pool
    }

    @MainActor
    internal func read<R>(_ cb: @escaping (Database) throws -> R) async throws -> R {
        try await withCheckedThrowingContinuation { continuation in
            pool.asyncRead { result in
                switch result {
                case .success(let db):
                    do {
                        try continuation.resume(returning: cb(db))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
