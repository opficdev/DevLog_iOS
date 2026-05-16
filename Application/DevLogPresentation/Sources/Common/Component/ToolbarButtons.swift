//
//  ToolbarButtons.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 3/1/26.
//

import SwiftUI
import DevLogDomain

struct ToolbarLeadingButton: ToolbarContent {
    var action: (() -> Void)?

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if #available(iOS 26.0, *) {
                Button(role: .cancel) {
                    action?()
                }
            } else {
                Button {
                    action?()
                } label: {
                    Text(String(localized: "common_cancel"))
                }
            }
        }
    }
}

struct ToolbarTrailingButton: ToolbarContent {
    var action: (() -> Void)?
    private var isDisabled: Bool = false

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    func disabled(_ isDisabled: Bool) -> ToolbarTrailingButton {
        var copy = self
        copy.isDisabled = isDisabled
        return copy
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if #available(iOS 26.0, *) {
                Button(role: .confirm) {
                    action?()
                }
                .disabled(isDisabled)
            } else {
                Button {
                    action?()
                } label: {
                    Text(String(localized: "common_confirm"))
                        .bold()
                }
                .disabled(isDisabled)
            }
        }
    }
}
