//
//  UserDefaultsStore.swift
//  DevLogData
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol UserDefaultsStore {
    func value<T: Codable>(forKey key: String) -> T?
    func setValue<T: Codable>(_ value: T?, forKey key: String)
    func removeValues(withPrefix prefix: String)
    func string(forKey key: String) -> String?
    func setString(_ value: String?, forKey key: String)
    func stringArray(forKey key: String) -> [String]
    func setStringArray(_ value: [String], forKey key: String)
    func bool(forKey key: String) -> Bool
    func setBool(_ value: Bool, forKey key: String)
}
