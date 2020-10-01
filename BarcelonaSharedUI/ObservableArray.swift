//
//  ObservableArray.swift
//  MyMessage for iOS
//
//  Created by Eric Rabil on 9/30/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

public class ObservableArray<T>: ObservableObject {
    @Published public var array: [T] = []
    public var cancellables = [AnyCancellable]()

    public init(array: [T]) {
        self.array = array
    }
    
    public subscript(_ index: Int) -> T {
        get {
            array[index]
        }
        set {
            array[index] = newValue
        }
    }
    
    public var count: Int {
        array.count
    }
    
    public func append(_ newElement: T) {
        array.append(newElement)
        print(array)
    }
    
    public func remove(at index: Int) {
        array.remove(at: index)
    }
}
