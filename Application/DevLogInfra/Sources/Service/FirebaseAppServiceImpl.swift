//
//  FirebaseAppServiceImpl.swift
//  DevLogInfra
//
//  Created by opfic on 5/15/26.
//

import DevLogData
import FirebaseCore

final class FirebaseAppServiceImpl: FirebaseAppService {
    private static var isConfigured = false

    func configure() {
        guard !Self.isConfigured else { return }

        FirebaseApp.configure()
        Self.isConfigured = true
    }
}
