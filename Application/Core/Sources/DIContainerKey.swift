//
//  DIContainerKey.swift
//  Core
//
//  Created by opfic on 5/15/26.
//

import SwiftUI

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: any DIContainer = AppDIContainer.shared
}

public extension EnvironmentValues {
    var diContainer: any DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
