//
//  Publishers.swift
//  Barcelona
//
//  Created by June Welker on 2/15/23.
//

import Combine
import Foundation

extension Publisher {
    @discardableResult
    public func retainingSink(
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
}

// Copied from // https://github.com/JohnSundell/AsyncCompatibilityKit  as it doesn't have macOS support.
@available(
    macOS,
    deprecated: 12.0,
    message: "AsyncCompatibilityKit is only useful when targeting macOS versions earlier than 12"
)
extension Publisher {
    /// Convert this publisher into an `AsyncThrowingStream` that
    /// can be iterated over asynchronously using `for try await`.
    /// The stream will yield each output value produced by the
    /// publisher and will finish once the publisher completes.
    public var values: AsyncThrowingStream<Output, Error> {
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

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            values.append(try await transform(element))
        }
        return values
    }
}
