//
//  FirebaseAppServiceImpl.swift
//  DevLogInfra
//
//  Created by opfic on 5/15/26.
//

import DevLogData
import FirebaseCore

final class FirebaseAppServiceImpl: FirebaseAppService {
    func configure() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}
