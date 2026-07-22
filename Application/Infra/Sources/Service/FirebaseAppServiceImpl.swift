//
//  FirebaseAppServiceImpl.swift
//  Infra
//
//  Created by opfic on 5/15/26.
//

import Data
import FirebaseCore
import FirebaseCrashlytics
import Foundation

final class FirebaseAppServiceImpl: FirebaseAppService {
    private enum InfoKey {
        static let crashlyticsCollectionEnabled = "FirebaseCrashlyticsCollectionEnabled"
    }

    private static var isConfigured = false

    func configure() {
        guard !Self.isConfigured else { return }

        FirebaseApp.configure()

        let crashlytics = Crashlytics.crashlytics()
        let policy = FirebaseCrashlyticsCollectionPolicy(
            infoDictionaryValue: Bundle.main.object(
                forInfoDictionaryKey: InfoKey.crashlyticsCollectionEnabled
            )
        )
        let actions = policy.actions(
            currentCollectionEnabled: crashlytics.isCrashlyticsCollectionEnabled()
        )

        for action in actions {
            switch action {
            case .deleteUnsentReports:
                crashlytics.deleteUnsentReports()
            case let .setCollectionEnabled(isEnabled):
                crashlytics.setCrashlyticsCollectionEnabled(isEnabled)
            }
        }

        Self.isConfigured = true
    }
}
