//
//  DIContainerKey.swift
//  DevLog
//
//  Created by 최윤진 on 12/14/25.
//

import SwiftUI

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: any DIContainer = AppDIContainer.shared
}

extension EnvironmentValues {
    var diContainer: any DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
