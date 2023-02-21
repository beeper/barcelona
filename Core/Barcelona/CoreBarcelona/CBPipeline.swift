////  CBPipeline.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/1/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Pwomise

// PassthroughSubject-style pipeline
public class CBPipeline<Value> {
    private var chains = [ObjectIdentifier: (Value) -> ()]()
    private var _cancel: () -> Void = {}

    @_spi(unitTestInternals) public init() {}

    public func send(_ value: Value) {
        for chain in chains.values {
            chain(value)
        }
    }

    public func cancel() {
        _cancel()
    }

    @discardableResult
    public func pipe(_ callback: @escaping (Value) -> Void) -> CBPipeline<Void> {
        let pipeline = CBPipeline<Void>()

        chains[ObjectIdentifier(pipeline)] = {
            pipeline.send(callback($0))
        }

        pipeline._cancel = {
            self.chains[ObjectIdentifier(pipeline)] = nil
            pipeline._cancel = {}
        }

        return pipeline
    }

    @discardableResult
    public func pipe<NewValue>(_ callback: @escaping (Value) -> NewValue) -> CBPipeline<NewValue> {
        let pipeline = CBPipeline<NewValue>()

        chains[ObjectIdentifier(pipeline)] = {
            pipeline.send(callback($0))
        }

        pipeline._cancel = {
            self.chains[ObjectIdentifier(pipeline)] = nil
            pipeline._cancel = {}
        }

        return pipeline
    }

    public func filter(_ callback: @escaping (Value) -> Bool) -> CBPipeline<Value> {
        let pipeline = CBPipeline<Value>()

        chains[ObjectIdentifier(pipeline)] = {
            guard callback($0) else {
                return
            }

            pipeline.send($0)
        }

        pipeline._cancel = {
            self.chains[ObjectIdentifier(pipeline)] = nil
            pipeline._cancel = {}
        }

        return pipeline
    }
}

// MARK: - Promise
extension CBPipeline {
    public func pipe<NewValue>(_ callback: @escaping (Value) -> Promise<NewValue>) -> CBPipeline<NewValue> {
        let pipeline = CBPipeline<NewValue>()

        chains[ObjectIdentifier(pipeline)] = {
            callback($0).then(pipeline.send)
        }

        pipeline._cancel = {
            self.chains[ObjectIdentifier(pipeline)] = nil
            pipeline._cancel = {}
        }

        return pipeline
    }
}
