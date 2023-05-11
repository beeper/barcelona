//
//  Async.swift
//  Extensions
//
//  Created by June Welker on 5/10/23.
//

import Foundation

// Stolen shamelessly from https://gist.github.com/swhitty/9be89dfe97dbb55c6ef0f916273bbb97
// I tested it in a playground where the `operation` was blocked by a non-async function and it still
// correctly threw the timeout error (which other implementations of this same concept didn't do), so
// I think this will work correctly. I pray.
public extension Task where Failure == Error {

    // Start a new Task with a timeout. If the timeout expires before the operation is
    // completed then the task is cancelled and an error is thrown.
    init(priority: TaskPriority? = nil, timeout: TimeInterval, operation: @escaping @Sendable () async throws -> Success) {
        self = Task(priority: priority) {
            try await withThrowingTaskGroup(of: Success.self) { group -> Success in
                group.addTask(operation: operation)
                group.addTask {
                    try await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    throw TimeoutError()
                }
                guard let success = try await group.next() else {
                    throw _Concurrency.CancellationError()
                }
                group.cancelAll()
                return success
            }
        }
    }
}

private struct TimeoutError: LocalizedError {
    var errorDescription: String? = "Task timed out before completion"
}
