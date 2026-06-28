//
//  WidgetConfigurationProvider.swift
//  DevLogData
//
//  Created by opfic on 6/28/26.
//

public protocol WidgetConfigurationProvider {
    func currentWidgetKinds() async throws -> Set<String>
}
