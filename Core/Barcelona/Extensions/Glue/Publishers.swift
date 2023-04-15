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
