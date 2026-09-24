//
//  AccountCard.swift
//  ProfileTab
//
//  Created by opfic on 9/24/26.
//

import SwiftUI
import PresentationShared

struct AccountCard: View {
    let isNetworkConnected: Bool
    let isLoading: Bool
    let showsSignOutProgress: Bool
    let onAccount: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings_account_section", bundle: PresentationResources.bundle)
                .font(.title3)
                .foregroundStyle(Color.primary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button(action: onAccount) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                            .foregroundStyle(Color.accent)
                            .frame(width: 48, height: 48)
                            .background(Color.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityHidden(true)

                        Text(String(localized: "settings_account", bundle: PresentationResources.bundle))
                            .foregroundStyle(Color.primary)

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .opacity(isNetworkConnected ? 1 : 0.5)
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)
                .disabled(!isNetworkConnected)

                Divider()
                    .padding(.leading, 84)
                    .padding(.trailing, 20)
                    .accessibilityHidden(true)

                Button(action: onSignOut) {
                    HStack(spacing: 16) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundStyle(Color.danger)
                            .frame(width: 48, height: 48)
                            .background(Color.danger.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .opacity(isNetworkConnected ? 1 : 0.5)
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)
                .disabled(!isNetworkConnected || isLoading)
            }
            .background(Color.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.border, lineWidth: 1)
            }
        }
    }
}
