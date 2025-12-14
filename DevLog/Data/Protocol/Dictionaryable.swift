//
//  Dictionaryable.swift
//  DevLog
//
//  Created by 최윤진 on 12/14/25.
//

import Foundation

protocol Dictionaryable: Encodable {
    func toDictionary() -> [String: Any]
}

extension Dictionaryable {
    func toDictionary() -> [String: Any] {
        guard let encodedData = try? JSONEncoder().encode(self),
              var dictionary = (try? JSONSerialization.jsonObject(with: encodedData)) as? [String: Any]
        else { return [:] }

        dictionary.removeValue(forKey: "id")
        return dictionary
    }
}
