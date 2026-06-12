//
//  SettingsView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/6/25.
//

import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    @Environment(NavigationRouter<ProfileRoute>.self) private var router
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        let connected = store.isNetworkConnected
        Form {
            Section {
                Button {
                    router.push(.theme)
                } label: {
                    HStack {
                        Text(String(localized: "settings_theme"))
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(store.theme.localizedName)
                            .foregroundStyle(Color.gray)
                    }
                }

                Button {
                    router.push(.pushNotification)
                } label: {
                    Text(String(localized: "settings_notifications"))
                        .foregroundStyle(connected ? Color.primary : Color.secondary)
                }
                .disabled(!connected)

                let dirSize = store.dirSize
                Button {
                    store.send(.tapRemoveCacheButton)
                } label: {
                    HStack {
                        Text(String(localized: "settings_clear_temp_data"))
                            .foregroundStyle(dirSize == 0 ? Color.secondary : .primary)
                        Spacer()
                        Text(formatFileSize(bytes: dirSize))
                            .foregroundStyle(Color.secondary.opacity(dirSize == 0 ? 0 : 1))
                    }
                }
                .disabled(dirSize == 0)
            }
            
            Section {
                if let appVersion = store.appVersion {
                    HStack {
                        Text(String(localized: "settings_version"))
                        Spacer()
                        Text(appVersion)
                    }
                }
                if let policyString = store.policyURL,
                   let url = URL(string: policyString) {
                    Link(destination: url) {
                        Text(String(localized: "settings_privacy_policy"))
                            .foregroundColor(Color.blue)
                    }
                }
                Button(action: {
                    if let appStoreString = store.appstoreUrl,
                       let url = URL(string: appStoreString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    VStack(alignment: .leading) {
                        Text(String(localized: "settings_join_beta"))
                        Text(String(localized: "settings_join_beta_subtitle"))
                            .foregroundStyle(Color.gray)
                            .font(.caption)
                    }
                }
            }
            
            Section {
                Button {
                    router.push(.account)
                } label: {
                    Text(String(localized: "settings_account"))
                }
                .disabled(!connected)
                Button(role: .destructive, action: {
                    store.send(.setAlert(.signOut))
                }) {
                    Text(String(localized: "settings_sign_out"))
                }
                .disabled(!connected)
            }
            
            HStack {
                Spacer()
                Button(role: .destructive, action: {
                    store.send(.setAlert(.deleteAuth))
                }) {
                    Text(String(localized: "settings_delete_account"))
                        .font(.headline)
                }
                .disabled(!connected)
                Spacer()
            }
        }
        .navigationTitle(String(localized: "nav_settings"))
        .navigationBarTitleDisplayMode(.inline)
        .alert($store.scope(state: \.alert, action: \.alert))
        .overlay {
            if store.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            store.send(.updateDirSize)
        }
    }

    private func formatFileSize(bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var value = Double(max(bytes, 0))
        var unitIndex = 0

        while 1024.0 <= value && unitIndex < units.count - 1 {
            value /= 1024.0
            unitIndex += 1
        }

        let truncated = floor(value * 100.0) / 100.0
        let numberString = truncated.formatted(
            .number.precision(.fractionLength(0...2))
        )
        return "\(numberString)\(units[unitIndex])"
    }
}
