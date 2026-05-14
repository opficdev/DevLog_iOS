//
//  UserDefaultsStore.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Foundation
import DevLogDomain
import DevLogDataDTO

public protocol UserDefaultsStore {
    func string(forKey key: String) -> String?
    func setString(_ value: String?, forKey key: String)
    func stringArray(forKey key: String) -> [String]
    func setStringArray(_ value: [String], forKey key: String)
    func bool(forKey key: String) -> Bool
    func setBool(_ value: Bool, forKey key: String)
}
