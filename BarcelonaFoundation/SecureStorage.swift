//
//  Storage.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 10/2/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

private let fileAttributes: [FileAttributeKey: Any] = [
    .posixPermissions: 0o700
]

#if os(iOS)
private let SecureStorageURL = URL(fileURLWithPath: "/var/mobile/Library/Application Support/com.ericrabil.imessage-rest/SecureStorage/", isDirectory: true)
#else
private let SecureStorageURL = URL(fileURLWithPath: ("~/Library/Application Support/com.ericrabil.imessage-rest/SecureStorage/" as NSString).expandingTildeInPath, isDirectory: true)
#endif

/**
    Keychain does not work for me because my code is not apple-sanctioned, so this class manages transactions to and from a secure directory.
 */
public class SecureStorage {
    public static var sharedInstance: SecureStorage {
        if let sharedInstance = _sharedInstance {
            return sharedInstance
        }
        _sharedInstance = try! SecureStorage(path: SecureStorageURL)
        return _sharedInstance!
    }
    
    private static var _sharedInstance: SecureStorage?
    private var memcache: [String: Any] = [:]
    
    public let path: URL
    public let cachingEnabled: Bool
    
    public init(path: URL, cache: Bool = true) throws {
        self.path = path
        self.cachingEnabled = cache
        
        if !FileManager.default.fileExists(atPath: path.absoluteString) {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: fileAttributes)
        }
        
        try FileManager.default.setAttributes(fileAttributes, ofItemAtPath: path.path)
    }
    
    private func absoluteFileURL(forKey key: String) -> URL {
        let url = path.appendingPathComponent(key)
        print(url)
        return url
    }
    
    private func absoluteFilePath(forKey key: String) -> String {
        absoluteFileURL(forKey: key).path
    }
    
    private func cache(_ data: Data?, forKey key: String) {
        if !cachingEnabled { return }
        memcache[key] = data
    }
    
    private func cache(_ string: String?, forKey key: String) {
        if !cachingEnabled { return }
        memcache[key] = string
    }
    
    private func cached(dataWithKey key: String) -> Data? {
        memcache[key] as? Data
    }
    
    private func cached(stringWithKey key: String) -> String? {
        memcache[key] as? String
    }
    
    private func write(data: Data?, forKey key: String) {
        let path = absoluteFileURL(forKey: key)
        
        if let newData = data {
            FileManager.default.createFile(atPath: path.path, contents: newData, attributes: fileAttributes)
        } else {
            try? FileManager.default.removeItem(at: path)
        }
    }
    
    public subscript(string key: String) -> String? {
        get {
            if let cached = cached(stringWithKey: key) {
                return cached
            }
            
            let coldValue = try? String(contentsOf: absoluteFileURL(forKey: key))
            cache(coldValue, forKey: key)
            return coldValue
        }
        set {
            write(data: newValue?.data(using: .utf8), forKey: key)
            cache(newValue, forKey: key)
        }
    }
    
    public subscript(data key: String) -> Data? {
        get {
            if let cached = cached(dataWithKey: key) {
                return cached
            }
            
            let coldValue = try? Data(contentsOf: absoluteFileURL(forKey: key))
            cache(coldValue, forKey: key)
            return coldValue
        }
        set {
            write(data: newValue, forKey: key)
            cache(newValue, forKey: key)
        }
    }
}
