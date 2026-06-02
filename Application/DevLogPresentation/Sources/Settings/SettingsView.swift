//
//  SettingsView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/6/25.
//

import SwiftUI
import DevLogDomain

struct SettingsView: View {
    @Environment(NavigationRouter<ProfileRoute>.self) private var router
    @State var viewModel: SettingsViewModel

    var body: some View {
        let connected = viewModel.state.isNetworkConnected
        Form {
            Section {
                Button {
                    router.push(.theme)
                } label: {
                    HStack {
                        Text(String(localized: "settings_theme"))
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(viewModel.state.theme.localizedName)
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

                let dirSize = viewModel.state.dirSize
                Button {
                    viewModel.send(.tapRemoveCacheButton)
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
                if let appVersion = viewModel.appVersion {
                    HStack {
                        Text(String(localized: "settings_version"))
                        Spacer()
                        Text(appVersion)
                    }
                }
                if let policyString = viewModel.policyURL,
                   let url = URL(string: policyString) {
                    Link(destination: url) {
                        Text(String(localized: "settings_privacy_policy"))
                            .foregroundColor(Color.blue)
                    }
                }
                Button(action: {
                    if let appStoreString = viewModel.appstoreUrl,
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
                    viewModel.send(.setAlert(isPresented: true, type: .signOut))
                }) {
                    Text(String(localized: "settings_sign_out"))
                }
                .disabled(!connected)
            }
            
            HStack {
                Spacer()
                Button(role: .destructive, action: {
                    viewModel.send(.setAlert(isPresented: true, type: .deleteAuth))
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
        .alert(
            viewModel.state.alertTitle,
            isPresented: Binding(
                get: { viewModel.state.showAlert },
                set: { viewModel.send(.setAlert(isPresented: $0)) }
            )) {
                alertButtons
            } message: {
                Text(viewModel.state.alertMessage)
            }
        .overlay {
            if viewModel.state.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            viewModel.send(.updateDirSize)
        }
    }

    @ViewBuilder
    private var alertButtons: some View {
        switch viewModel.state.alertType {
        case .signOut:
            Button(String(localized: "common_cancel"), role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
            Button(String(localized: "common_confirm"), role: .destructive) {
                viewModel.send(.tapSignOutButton)
            }
        case .deleteAuth:
            Button(String(localized: "common_cancel"), role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
            Button(String(localized: "settings_delete_account_action"), role: .destructive) {
                viewModel.send(.tapDeleteAuthButton)
            }
        case .removeCache:
            Button(String(localized: "common_cancel"), role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
            Button(String(localized: "common_confirm"), role: .destructive) {
                viewModel.send(.confirmRemoveCache)
            }
        case .error, .none:
            Button(String(localized: "common_close"), role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
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
