//
//  Logger.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 7/29/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public extension Promise {
    func endingOperation(_ operation: LoggingOperation, takingOutput callback: @escaping (Output) -> ()) -> Promise<Output> {
        always { result -> Promise<Output> in
            switch result {
            case .success(let output):
                callback(output)
            case .failure(let error):
                operation.end("failed with error: %@", error as NSError)
            }
            
            return Promise.completed(result)
        }
    }
    
    func endingOperation(forFailureOnly operation: LoggingOperation, _ callback: ((Error) -> ())? = nil) -> Promise<Output> {
        self.catch { error -> Promise<Output> in
            if let callback = callback {
                callback(error)
            } else {
                operation.end("failed with error: %@", error as NSError)
            }
            
            return Promise.failure(error)
        }
    }
}
