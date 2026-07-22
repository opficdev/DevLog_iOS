//
//  FirebaseCrashlyticsCollectionPolicy.swift
//  Infra
//
//  Created by opfic on 7/22/26.
//

import Foundation

struct FirebaseCrashlyticsCollectionPolicy {
    enum Action: Equatable {
        case deleteUnsentReports
        case setCollectionEnabled(Bool)
    }

    let isCollectionEnabled: Bool

    var shouldRemoveStoredOverride: Bool {
        !isCollectionEnabled
    }

    init(infoDictionaryValue: Any?) {
        guard let value = infoDictionaryValue as? NSNumber,
              CFGetTypeID(value) == CFBooleanGetTypeID() else {
            isCollectionEnabled = false
            return
        }

        isCollectionEnabled = value.boolValue
    }

    func actions(currentCollectionEnabled: Bool) -> [Action] {
        var actions = [Action]()

        if !currentCollectionEnabled {
            actions.append(.deleteUnsentReports)
        }
        actions.append(.setCollectionEnabled(isCollectionEnabled))

        return actions
    }
}
