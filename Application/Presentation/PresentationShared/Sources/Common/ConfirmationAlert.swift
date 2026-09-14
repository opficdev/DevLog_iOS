//
//  ConfirmationAlert.swift
//  PresentationShared
//
//  Created by opfic on 9/14/26.
//

import SwiftUI

public struct ConfirmationAlertConfiguration {
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String

    public init(
        title: String,
        message: String,
        cancelTitle: String,
        confirmTitle: String
    ) {
        self.title = title
        self.message = message
        self.cancelTitle = cancelTitle
        self.confirmTitle = confirmTitle
    }
}

public extension View {
    func confirmationAlert(
        isPresented: Binding<Bool>,
        configuration: ConfirmationAlertConfiguration,
        isConfirming: Bool = false,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            ConfirmationAlertModifier(
                isPresented: isPresented,
                configuration: configuration,
                isConfirming: isConfirming,
                onConfirm: onConfirm
            )
        )
    }
}

private struct ConfirmationAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let configuration: ConfirmationAlertConfiguration
    let isConfirming: Bool
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        ZStack {
            content
                .allowsHitTesting(!isPresented)

            if isPresented {
                Color.black.opacity(0.32)
                    .ignoresSafeArea()
                    .transition(.opacity)

                alertCard
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: isPresented)
    }

    private var alertCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(configuration.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)

                Text(configuration.message)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)

            Divider()

            HStack(spacing: 0) {
                Button(configuration.cancelTitle) {
                    isPresented = false
                }
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .disabled(isConfirming)

                Divider()

                Button {
                    isPresented = false
                    onConfirm()
                } label: {
                    if isConfirming {
                        ProgressView()
                            .tint(Color.accent)
                    } else {
                        Text(configuration.confirmTitle)
                    }
                }
                .foregroundStyle(Color.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .disabled(isConfirming)
            }
            .font(.body)
            .frame(height: 56)
        }
        .frame(maxWidth: 420)
        .background(Color.surface, in: .rect(cornerRadius: 28))
        .clipShape(.rect(cornerRadius: 28))
        .shadow(color: Color.black.opacity(0.18), radius: 24, y: 12)
        .accessibilityElement(children: .contain)
    }
}
