//
//  AccountCard.swift
//  ProfileTab
//
//  Created by opfic on 9/24/26.
//

import SwiftUI
import PresentationShared

struct AccountCard: View {
    @ScaledMetric(relativeTo: .headline) private var iconSize = 36
    let isNetworkConnected: Bool
    let isLoading: Bool
    let showsSignOutProgress: Bool
    let onAccount: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings_account_section", bundle: PresentationResources.bundle)
                .font(.title3.bold())
                .foregroundStyle(Color.primary)

            VStack(spacing: 0) {
                Button(action: onAccount) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .font(.headline)
                            .foregroundStyle(Color.accent)
                            .frame(width: iconSize, height: iconSize)
                            .background(Color.accent.opacity(0.09), in: .rect(cornerRadius: 10))
                            .accessibilityHidden(true)

                        Text(String(localized: "settings_account", bundle: PresentationResources.bundle))
                            .foregroundStyle(Color.primary)

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .opacity(isNetworkConnected ? 1 : 0.5)
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)
                .disabled(!isNetworkConnected)

                Divider()
                    .padding(.leading, 64)
                    .padding(.trailing, 16)
                    .accessibilityHidden(true)

                Button(action: onSignOut) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .foregroundStyle(Color.danger)
                            .frame(width: iconSize, height: iconSize)
                            .background(Color.danger.opacity(0.09), in: .rect(cornerRadius: 10))
                            .accessibilityHidden(true)

                        Text(String(localized: "settings_sign_out", bundle: PresentationResources.bundle))
                            .foregroundStyle(Color.danger)

                        Spacer(minLength: 8)

                        if showsSignOutProgress {
                            ProgressView()
                        }

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .opacity(isNetworkConnected ? 1 : 0.5)
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)
                .disabled(!isNetworkConnected || isLoading)
            }
            .background(Color.surface, in: .rect(cornerRadius: 16))
        }
    }
}
