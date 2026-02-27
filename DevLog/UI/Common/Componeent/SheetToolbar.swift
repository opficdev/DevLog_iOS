//
//  SheetToolbar.swift
//  DevLog
//
//  Created by 최윤진 on 2/27/26.
//

import SwiftUI

struct SheetToolbar: ToolbarContent {
    let onCancel: () -> Void
    let onConfirm: () -> Void
    let isConfirmEnabled: Bool

    init(
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void,
        isConfirmEnabled: Bool = true
    ) {
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        self.isConfirmEnabled = isConfirmEnabled
    }

    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .cancel) {
                    onCancel()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .confirm) {
                    onConfirm()
                }
                .disabled(!isConfirmEnabled)
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onCancel()
                } label: {
                    Text("취소")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onConfirm()
                } label: {
                    Text("확인")
                        .bold()
                }
                .disabled(!isConfirmEnabled)
            }
        }
    }
}
