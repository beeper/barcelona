//
//  Promise.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 7/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Combine

public extension DispatchQueue {
    func promise<Output>(_ cb: @escaping () -> Output) -> Promise<Output, Never> {
        Promise { resolve in
            self.async {
                resolve(cb())
            }
        }
    }
    
    func promise<Output>(_ cb: @escaping () throws -> Output) -> Promise<Output, Error> {
        Promise { resolve, reject in
            self.async {
                do { try resolve(cb()) }
                catch { reject(error) }
            }
        }
    }
}

public class Promise<Output, Failure: Error>: Publisher {
    private let backing: AnyPublisher<Output, Failure>
    private var cancellables = Set<AnyCancellable>()
    
    public static func success(_ value: Output) -> Promise<Output, Failure> {
        Promise(backing: Just(value).setFailureType(to: Failure.self).eraseToAnyPublisher())
    }
    
    public static func failure(_ value: Failure) -> Promise<Output, Failure> {
        Promise(backing: Fail(error: value).eraseToAnyPublisher())
    }
    
    public static func whenAllSucceed(_ promises: [Promise<Output, Failure>]) -> Promise<[Output], Failure> {
        guard promises.count > 0 else {
            return Promise<[Output], Failure>(backing: Just([Output]()).setFailureType(to: Failure.self).share())
        }
        
        return Promise<[Output], Failure>(backing: Publishers.MergeMany(promises).collect())
    }
    
    public init(_ cb: @escaping (@escaping (Output) -> (), @escaping (Failure) -> ()) -> ()) {
        backing = Future { completion in
            cb({ output in completion(.success(output)) }, { failure in completion(.failure(failure)) })
        }.eraseToAnyPublisher()
    }
    
    public init(_ cb: @escaping (@escaping (Output) -> ()) -> ()) {
        backing = Future<Output, Failure> { completion in
            cb({ output in completion(.success(output)) })
        }.eraseToAnyPublisher()
    }
    
    public init(_ cb: @escaping () -> Output) {
        backing = Future<Output, Failure> { completion in
            completion(.success(cb()))
        }.eraseToAnyPublisher()
    }
    
    public init(_ cb: @escaping () throws -> Output) {
        backing = Future<Output, Failure> { completion in
            do {
                completion(.success(try cb()))
            } catch {
                completion(.failure(error as! Failure))
            }
        }.eraseToAnyPublisher()
    }
    
    public init<Pub: Publisher>(backing: Pub) where Pub.Output == Output, Pub.Failure == Failure {
        self.backing = backing.eraseToAnyPublisher()
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        backing.receive(subscriber: subscriber)
    }
    
    public func then<NewValue>(_ cb: @escaping (Output) -> NewValue) -> Promise<NewValue, Failure> {
        Promise<NewValue, Failure>(backing: backing.map(cb).eraseToAnyPublisher())
    }
    
    public func then<Pub: Publisher>(_ cb: @escaping (Output) -> Pub) -> Promise<Pub.Output, Failure> where Pub.Failure == Failure {
        Promise<Pub.Output, Failure>(backing: backing.flatMap(cb))
    }
    
    public func then<NewOutput>(_ cb: @escaping (Output) throws -> NewOutput) -> Promise<NewOutput, Error> {
        Promise<NewOutput, Error>(backing: backing.tryMap(cb))
    }
    
    public func receive<Schedule: Scheduler>(on scheduler: Schedule) -> Promise<Output, Failure> {
        Promise(backing: backing.receive(on: scheduler))
    }
    
    public func observe(_ cb: @escaping (Output) -> ()) -> Self {
        whenSuccess(cb)
        return self
    }
    
    public func pipe(_ resolve: @escaping (Output) -> Void, _ reject: @escaping (Failure) -> Void) {
        sink(receiveCompletion: { completion in
            guard case .failure(let error) = completion else {
                return
            }
            
            reject(error)
        }, receiveValue: resolve).store(in: &cancellables)
    }
    
    @inline(__always)
    public func map<NewOutput>(_ cb: @escaping (Output) -> NewOutput) -> Promise<NewOutput, Error> {
        then(cb)
    }
    
    @inline(__always)
    public func flatMap<Pub: Publisher>(_ cb: @escaping (Output) -> Pub) -> Promise<Pub.Output, Failure> where Pub.Failure == Failure {
        then(cb)
    }
    
    @discardableResult
    public func whenComplete(_ cb: @escaping (Result<Output, Failure>) -> Void) -> Self {
        var cancellable: AnyCancellable?
        
        var receivedValue = false
        let finish = {
            guard let cancellable = cancellable else {
                return
            }
            
            self.cancellables.remove(cancellable)
            cancellable.cancel()
        }
        
        cancellable = sink(receiveCompletion: { completion in
            finish()
            
            switch completion {
            case .failure(let error):
                cb(.failure(error))
            default:
                if receivedValue {
                    break
                }
                
                fatalError("unknown completion received in promise")
            }
        }, receiveValue: { value in
            receivedValue = true
            finish()
            cb(.success(value))
        })
        
        cancellable!.store(in: &cancellables)
        
        return self
    }
    
    @discardableResult
    public func whenSuccess(_ cb: @escaping (Output) -> Void) -> Self {
        whenComplete { result in
            guard case .success(let output) = result else {
                return
            }
            
            cb(output)
        }
    }
    
    @discardableResult
    public func whenFailure(_ cb: @escaping (Failure) -> Void) -> Self {
        whenComplete { result in
            guard case .failure(let error) = result else {
                return
            }
            
            cb(error)
        }
    }
}

public protocol OptionalConvertible {
    associatedtype Element
    var asOptional: Optional<Element> { get }
}

extension Optional: OptionalConvertible {
    public var asOptional: Optional<Wrapped> { return self }
}

public extension Promise where Output: OptionalConvertible {
    func assert(_ error: @autoclosure @escaping () -> Error) -> Promise<Output.Element, Error> {
        then { output in
            guard let value = output.asOptional else {
                throw error()
            }
            
            return value
        }
    }
}
