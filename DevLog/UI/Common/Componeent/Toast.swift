//
//  Toast.swift
//  DevLog
//
//  Created by 최윤진 on 2/10/26.
//

import SwiftUI

extension View {
    func toast<Label: View>(
        isPresented: Binding<Bool>,
        duration: TimeInterval = 2,
        action: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                ToastOverlayView(
                    isPresented: isPresented,
                    duration: duration,
                    action: action,
                    onDismiss: onDismiss,
                    label: label
                )
                .padding(.horizontal, 12)
            }
    }
}

private struct ToastOverlayView<Label: View>: View {
    @Binding var isPresented: Bool
    let duration: TimeInterval
    let action: (() -> Void)?
    let onDismiss: (() -> Void)?
    @ViewBuilder let label: () -> Label

    @State private var yOffset: CGFloat = 0
    @State private var opacityValue: Double = 0
    @State private var dismissWorkItem: DispatchWorkItem?
    @State private var isTapped: Bool = false

    var body: some View {
        if isPresented {
            ToastCardView(
                label,
                color: action == nil ? .primary : .blue
            )
            .offset(y: yOffset)
            .opacity(opacityValue)
            .onAppear {
                presentAnimated()
                scheduleDismiss()
            }
            .onDisappear {
                dismissWorkItem?.cancel()
                dismissWorkItem = nil
                isPresented = false

                // 토스트를 탭하지 않고 자동으로 사라진 경우에만 onDismiss 호출
                if !isTapped {
                    onDismiss?()
                }
            }
            .onTapGesture {
                isTapped = true
                dismissAnimated()
                action?()
            }
            .transition(.identity)
        }
    }

    private func presentAnimated() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 0.0)) {
            yOffset = -100
            opacityValue = 1
        }
    }

    private func scheduleDismiss() {
        let workItem = DispatchWorkItem {
            dismissAnimated()
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func dismissAnimated() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        withAnimation(.easeInOut(duration: 0.2)) {
            yOffset = 0
            opacityValue = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

private struct ToastCardView<Label: View>: View {
    @ViewBuilder let label: Label
    let color: Color

    init(
        @ViewBuilder _ label: @escaping () -> Label,
        color: Color = .primary
    ) {
        self.label = label()
        self.color = color
    }

    var body: some View {
        self.label
            .foregroundStyle(color)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .glassEffect()
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay {
                if #unavailable(iOS 26.0) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(.systemGray4).opacity(0.2), lineWidth: 1)
                }
            }
            .shadow(color: Color(.systemGray2).opacity(0.4), radius: 18, x: 0, y: 10)
    }
}
