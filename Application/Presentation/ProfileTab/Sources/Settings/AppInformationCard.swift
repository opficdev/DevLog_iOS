//
//  AppInformationCard.swift
//  ProfileTab
//
//  Created by opfic on 9/24/26.
//

import SwiftUI
import PresentationShared

struct AppInformationCard: View {
    let appVersion: String?
    let privacyPolicyURL: URL?
    let betaTestURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings_information_section", bundle: PresentationResources.bundle)
                .font(.title3)
                .foregroundStyle(Color.primary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                if let appVersion {
                    HStack(spacing: 16) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundStyle(Color.accent)
                            .frame(width: 48, height: 48)
                            .background(Color.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityHidden(true)

                        Text(String(localized: "settings_version", bundle: PresentationResources.bundle))
                            .foregroundStyle(Color.primary)

                        Spacer(minLength: 8)

                        Text(appVersion)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }

                if let privacyPolicyURL {
                    if appVersion != nil {
                        Divider()
                            .padding(.leading, 84)
                            .padding(.trailing, 20)
                            .accessibilityHidden(true)
                    }

                    Link(destination: privacyPolicyURL) {
                        HStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.title3)
                                .foregroundStyle(Color.accent)
                                .frame(width: 48, height: 48)
                                .background(Color.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                                .accessibilityHidden(true)

                            Text(String(
                                localized: "settings_privacy_policy",
                                bundle: PresentationResources.bundle
                            ))
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
                        .accessibilityElement(children: .combine)
                    }
                    .buttonStyle(.plain)
                }

                if let betaTestURL {
                    if appVersion != nil || privacyPolicyURL != nil {
                        Divider()
                            .padding(.leading, 84)
                            .padding(.trailing, 20)
                            .accessibilityHidden(true)
                    }

                    Link(destination: betaTestURL) {
                        HStack(spacing: 16) {
                            Image(systemName: "flask")
                                .font(.title3)
                                .foregroundStyle(Color.accent)
                                .frame(width: 48, height: 48)
                                .background(Color.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "settings_join_beta", bundle: PresentationResources.bundle))
                                    .foregroundStyle(Color.primary)
                                Text(String(
                                    localized: "settings_join_beta_subtitle",
                                    bundle: PresentationResources.bundle
                                ))
                                .font(.footnote)
                                .foregroundStyle(Color.textSecondary)
                            }

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
                        .accessibilityElement(children: .combine)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.border, lineWidth: 1)
            }
        }
    }
}
