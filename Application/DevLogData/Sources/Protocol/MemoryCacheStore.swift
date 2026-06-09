//
//  MemoryCacheStore.swift
//  DevLogData
//
//  Created by opfic on 6/9/26.
//

import Foundation

public protocol MemoryCacheStore {
    func value<T: Codable>(forKey key: String) -> T?
    func setValue<T: Codable>(_ value: T?, forKey key: String)
}
