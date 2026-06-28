//
//  WidgetConfigurationProviderImpl.swift
//  DevLogWidget
//
//  Created by opfic on 6/28/26.
//

import WidgetKit
import DevLogData

public final class WidgetConfigurationProviderImpl: WidgetConfigurationProvider {
    public init() { }

    public func currentWidgetKinds() async throws -> Set<String> {
        try await withCheckedThrowingContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                continuation.resume(
                    with: result.map { configurations in
                        Set(configurations.map(\.kind))
                    }
                )
            }
        }
    }
}
