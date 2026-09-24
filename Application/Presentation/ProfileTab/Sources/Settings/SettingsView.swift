//
//  SettingsView.swift
//  ProfileTab
//
//  Created by opfic on 5/6/25.
//

import SwiftUI
import Domain
import PresentationShared

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    let onNavigate: (ProfileRoute) -> Void

    private var privacyPolicyURL: URL? {
        guard let policyString = store.policyURL else { return nil }
        return URL(string: policyString)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                AppSettingsCard(
                    themeName: store.theme.localizedName(in: PresentationResources.bundle),
                    isNetworkConnected: store.isNetworkConnected,
                    onTheme: { onNavigate(.theme) },
                    onNotifications: { onNavigate(.pushNotification) }
                )

                if store.appVersion != nil || privacyPolicyURL != nil || store.betaTestURL != nil {
                    AppInformationCard(
                        appVersion: store.appVersion,
                        privacyPolicyURL: privacyPolicyURL,
                        betaTestURL: store.betaTestURL
                    )
                }

                AccountCard(
                    isNetworkConnected: store.isNetworkConnected,
                    isLoading: store.isLoading,
                    showsSignOutProgress: store.activeLoadingRow == .signOut,
                    onAccount: { onNavigate(.account) },
                    onSignOut: { store.send(.setAlert(.signOut)) }
                )

                deleteAccountContent
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.appBackground)
        .navigationTitle(String(localized: "nav_settings", bundle: PresentationResources.bundle))
        .navigationBarTitleDisplayMode(.inline)
        .prominentAlert(store, state: \.alert, action: \.alert)
    }

    private var deleteAccountContent: some View {
        VStack(spacing: 16) {
            Divider()

            Button {
                store.send(.setAlert(.deleteAuth))
            } label: {
                if store.activeLoadingRow == .deleteAuth {
                    ProgressView()
                } else {
                    Text(String(localized: "settings_delete_account", bundle: PresentationResources.bundle))
                        .foregroundStyle(Color.danger)
                }
            }
            .buttonStyle(.plain)
            .disabled(!store.isNetworkConnected || store.isLoading)

            Text("settings_delete_account_subtitle", bundle: PresentationResources.bundle)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
}
