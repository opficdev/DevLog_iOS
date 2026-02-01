//
//  Dictionaryable.swift
//  DevLog
//
//  Created by 최윤진 on 12/14/25.
//

import FirebaseFirestore

protocol Dictionaryable: Encodable {
    func toDictionary() -> [String: Any]
}

extension Dictionaryable {
    func toDictionary() -> [String: Any] {
        let encoder = Firestore.Encoder()
        guard var dictionary = try? encoder.encode(self) else { return [:] }

        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let key = child.label else { continue }
            if isNilValue(child.value) {
                dictionary[key] = NSNull()
            }
        }

        dictionary.removeValue(forKey: "id")
        return dictionary
    }

    private func isNilValue(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)
        return mirror.displayStyle == .optional && mirror.children.isEmpty
    }
}
