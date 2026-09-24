//
//  AppSettingsCard.swift
//  ProfileTab
//
//  Created by opfic on 9/24/26.
//

import SwiftUI
import PresentationShared

struct AppSettingsCard: View {
    let themeName: String
    let isNetworkConnected: Bool
    let onTheme: () -> Void
    let onNotifications: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings_app_section", bundle: PresentationResources.bundle)
                .font(.title3)
                .foregroundStyle(Color.primary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button(action: onTheme) {
                    HStack(spacing: 16) {
                        Image(systemName: "desktopcomputer")
                            .font(.title3)
                            .foregroundStyle(Color.accent)
                            .frame(width: 48, height: 48)
                            .background(Color.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityHidden(true)

                        Text(String(localized: "settings_theme", bundle: PresentationResources.bundle))
                            .foregroundStyle(Color.primary)

                        Spacer(minLength: 8)

                        Text(themeName)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.trailing)

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 84)
                    .padding(.trailing, 20)
                    .accessibilityHidden(true)

                Button(action: onNotifications) {
                    HStack(spacing: 16) {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundStyle(Color.accent)
                            .frame(width: 48, height: 48)
                            .background(Color.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityHidden(true)

                        Text(String(localized: "settings_notifications", bundle: PresentationResources.bundle))
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
            }
            .background(Color.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.border, lineWidth: 1)
            }
        }
    }
}
