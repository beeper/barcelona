//
//  AnyPublisher.swift
//  Barcelona
//
//  Created by June on 2/2/23.
//

import Foundation
import Combine

public extension AnyPublisher {
    static func success(_ success: Output) -> AnyPublisher<Output, Failure> {
        Just(success).setFailureType(to: Failure.self).eraseToAnyPublisher()
    }

    static func failure(_ failure: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: failure).eraseToAnyPublisher()
    }
}

extension Publisher {
    /// The same function as `sink(receiveCompletion:receiveValue:)`, except retaining
    /// the cancellable that is created by that call until the completion runs to ensure
    /// that this pipeline doesn't get destroyed.
    @discardableResult public func retainingSink(
        receiveCompletion: @escaping (Subscribers.Completion<Self.Failure>) -> Void,
        receiveValue: @escaping (Self.Output) -> Void
    ) -> AnyCancellable? {
        // Create a temporary cancellable to ensure that this
        // cancellable doesn't go away until completion
        var tempCancellable: AnyCancellable?

        tempCancellable = sink(receiveCompletion: { completion in
            receiveCompletion(completion)

            // We can kill the cancellable here since the block to run completion
            // is already going, but we use `withExtendedLifetime` to ensure
            // that `tempCancellable` isn't killed before now
            tempCancellable = withExtendedLifetime(tempCancellable) { nil }
        }, receiveValue: receiveValue)

        // And then return the cancellable if they do want to further use it
        // It's safe to force-unwrap since we just created it and no events
        // could've been sent through it to run completion and make it nil yet
        return tempCancellable
    }
}
