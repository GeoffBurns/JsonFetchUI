//
//  CustomCache.swift
//
//  Created by Ilker Baltaci on 16.06.20.
//  Blog Post : https://blog.devgenius.io/caching-with-nscache-in-ios-2e97be8d6b53
//  Source : https://gist.github.com/IronLeash/7d4a5583a85d60cb36d2e35e53427c42

import Foundation

public final class CustomCache<Key: Hashable, Value> {

    private let cache = NSCache<KeyWrapper, CacheEntry>()

    private final class CacheEntry {
        let value: Value
        let expiryDate: Date?
        
        init(value: Value, expiryDate: Date? = nil) {
            self.value = value
            self.expiryDate = expiryDate
        }
    }
    
    private final class KeyWrapper: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }
        
        override var hash: Int { key.hashValue }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? KeyWrapper else { return false }
            return value.key == key
        }
    }
}

public extension CustomCache {
    func insert(_ value: Value, forKey key: Key, timeToLiveInMinutes: UInt) {
        let timeInSeconds = Double(timeToLiveInMinutes*60)
        let expiryDate = Date().addingTimeInterval(timeInSeconds)
        let entry = CacheEntry(value: value,expiryDate: expiryDate)

        cache.setObject(entry, forKey: KeyWrapper(key))
    }
    
    func insert(_ value: Value, forKey key: Key) {
        let entry = CacheEntry(value: value)
        cache.setObject(entry, forKey: KeyWrapper(key))
    }

    func value(forKey key: Key) -> Value? {
        guard let entry = cache.object(forKey: KeyWrapper(key)) else { return nil }
        
        guard let expiryDate = entry.expiryDate else { return entry.value }

        
        guard Date() < expiryDate else {
            // Discard values that have expired
            removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func removeValue(forKey key: Key) {
        cache.removeObject(forKey: KeyWrapper(key))
    }
    
    subscript(key: Key) -> Value? {
        get { return value(forKey: key) }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                removeValue(forKey: key)
                return
            }
            insert(value, forKey: key)
        }
    }
}
