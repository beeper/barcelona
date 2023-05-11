//
//  Combine.swift
//  Extensions
//
//  Created by June Welker on 5/10/23.
//

import Foundation
import Combine

public extension Publisher {
    @discardableResult
    func retainingSink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping (Output) -> Void
    ) -> AnyCancellable? {
        var cancellable: AnyCancellable?
        cancellable = sink(
            receiveCompletion: {
                receiveCompletion($0)

                withExtendedLifetime(cancellable) { cancellable = nil }
            },
            receiveValue: receiveValue
        )

        return cancellable
    }

    func asyncFirst() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            first().retainingSink { completion in
                if case let .failure(error) = completion {
                    continuation.resume(throwing: error)
                }
            } receiveValue: { value in
                continuation.resume(returning: value)
            }
        }
    }
}

extension Publisher where Failure == Never {
    public func asyncFirst() async -> Output {
        await withCheckedContinuation { continuation in
            first().retainingSink { _ in } receiveValue: { value in
                continuation.resume(returning: value)
            }
        }
    }
}

// Copied from // https://github.com/JohnSundell/AsyncCompatibilityKit  as it doesn't have macOS support.
@available(
    macOS,
    deprecated: 12.0,
    message: "AsyncCompatibilityKit is only useful when targeting macOS versions earlier than 12"
)
public extension Publisher {
    /// Convert this publisher into an `AsyncThrowingStream` that
    /// can be iterated over asynchronously using `for try await`.
    /// The stream will yield each output value produced by the
    /// publisher and will finish once the publisher completes.
    var values: AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { continuation in
            var cancellable: AnyCancellable?
            let onTermination = { cancellable?.cancel() }

            continuation.onTermination = { @Sendable _ in
                onTermination()
            }

            cancellable = sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                },
                receiveValue: { value in
                    continuation.yield(value)
                }
            )
        }
    }
}
