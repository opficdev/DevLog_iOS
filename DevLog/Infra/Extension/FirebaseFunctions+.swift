//
//  FirebaseFunctions+.swift
//  DevLog
//
//  Created by opfic on 3/16/26.
//

import FirebaseFunctions
import DevLogDataCommon
import DevLogDataDTO
import DevLogDataProtocol

extension Functions {
    func httpsCallable(_ name: some RawRepresentable<String>) -> HTTPSCallable {
        httpsCallable(name.rawValue)
    }
}
