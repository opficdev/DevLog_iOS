//
//  FirebaseFunctions+.swift
//  DevLog
//
//  Created by opfic on 3/16/26.
//

import FirebaseFunctions
import DevLogData

extension Functions {
    func httpsCallable(_ name: some RawRepresentable<String>) -> HTTPSCallable {
        httpsCallable(name.rawValue)
    }
}
