//
//  View+Refreshable.swift
//  NotificationTab
//
//  Created by opfic on 7/28/26.
//

import SwiftUI

enum PullToRefreshAvailability {
    static var isEnabled: Bool {
        if #available(iOS 18.0, *) {
            return true
        } else {
            return false
        }
    }
}

extension View {
    @ViewBuilder
    func refreshable(
        isEnabled: Bool,
        action: @escaping @MainActor @Sendable () async -> Void
    ) -> some View {
        if isEnabled {
            refreshable { await action() }
        } else {
            self
        }
    }
}
