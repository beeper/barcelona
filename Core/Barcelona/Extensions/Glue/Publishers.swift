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
    func asyncMap<T>(_ transform: @escaping (Element) async -> T) async -> [T] {
        await withTaskGroup(of: T.self, returning: [T].self) { group in
            for item in self {
                group.addTask {
                    await transform(item)
                }
            }

            return await group.reduce(into: []) { $0.append($1) }
        }
    }
}
