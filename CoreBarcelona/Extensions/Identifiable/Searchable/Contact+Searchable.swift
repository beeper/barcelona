//
//  Contacts+Searchable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Contacts
import IMCore
import NIO

public struct ContactSearchParameters: QueryParameters {
    public var ids: [String]?
    public var first_name: String?
//    var middle_name: String?
    public var last_name: String?
    public var nickname: String?
    public var has_picture: Bool?
    public var handles: [String]?
    public var limit: Int?
    public var page: Int?
    
    fileprivate var parameters: [ContactSearchParameter] {
        var parameters: [ContactSearchParameter] = []
        
        if let ids = ids {
            parameters.append(.ids(ids))
        }
        
        if let firstName = first_name {
            parameters.append(.firstName(firstName.lowercased()))
        }
        
        if let lastName = last_name {
            parameters.append(.lastName(lastName.lowercased()))
        }
        
        if let nickname = nickname {
            parameters.append(.nickname(nickname.lowercased()))
        }
        
        if let hasPicture = has_picture {
            parameters.append(.hasPicture(hasPicture))
        }
        
        if let handles = handles {
            parameters.append(.handles(handles))
        }
        
        return parameters
    }
}

private extension CNContact {
    var handleIDs: [String] {
        Registry.sharedInstance.imHandleIDs(forContact: self)
    }
}

private enum ContactSearchParameter: SearchParameter {
    case ids([String])
    case firstName(String)
    case lastName(String)
    case nickname(String)
    case hasPicture(Bool)
    case handles([String])
    
    func test(_ person: CNContact) -> Bool {
        switch self {
        case .ids(let ids):
            if !ids.contains(person.id) {
                return false
            }
        case .firstName(let firstName):
            if !(person.givenName.lowercased().contains(firstName)) {
                return false
            }
        case .lastName(let lastName):
            if !(person.familyName.lowercased().contains(lastName)) {
                return false
            }
        case .nickname(let nickname):
            if !(person.nickname.lowercased().contains(nickname)) {
                return false
            }
        case .hasPicture(let hasPicture):
            if hasPicture {
                if person.imageData == nil {
                    return false
                }
            } else {
                if person.imageData != nil {
                    return false
                }
            }
        case .handles(let handles):
            if !person.handleIDs.contains(items: handles) {
                return false
            }
        }

        return true
    }
}

extension Contact: Searchable {
    public static func resolve(withParameters rawParameters: ContactSearchParameters, on eventLoop: EventLoop?) -> EventLoopFuture<[Contact]> {
        let eventLoop = eventLoop ?? messageQuerySystem.next()
        
        let parameters = rawParameters.parameters
        
        if parameters.count == 0 {
            return eventLoop.makeSucceededFuture([])
        }
        
        return eventLoop.makeSucceededFuture(IMContactStore.sharedInstance()!.allContacts.filter {
            parameters.test($0)
        }.map {
            Contact($0)
        })
    }
}
