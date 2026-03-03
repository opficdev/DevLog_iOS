//
//  SettingView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

struct SettingView: View {
    @Environment(\.diContainer) var container: DIContainer
    @State var viewModel: SettingViewModel
    @Environment(NavigationRouter.self) var router

    var body: some View {
        Form {
            Section {
                Button {
                    router.push(Path.theme)
                } label: {
                    HStack {
                        Text("테마")
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(viewModel.state.theme.localizedName)
                            .foregroundStyle(Color.gray)
                    }
                }

                Button {
                    router.push(Path.pushNotification)
                } label: {
                    Text("알림")
                        .foregroundStyle(Color.primary)
                }

                let dirSize = viewModel.state.dirSize
                Button {
                    viewModel.send(.tapRemoveCacheButton)
                } label: {
                    HStack {
                        Text("임시 데이터 삭제")
                            .foregroundStyle(dirSize == 0 ? Color.secondary : .primary)
                        Spacer()
                        Text(formatFileSize(bytes: dirSize))
                            .foregroundStyle(Color.secondary.opacity(dirSize == 0 ? 0 : 1))
                    }
                }
                .disabled(dirSize == 0)
            }
            
            Section {
                if let appVersion = viewModel.state.appVersion {
                    HStack {
                        Text("버전 정보")
                        Spacer()
                        Text(appVersion)
                    }
                }
                if let ppurl = viewModel.state.policyURL {
                    Link(destination: URL(string: ppurl)!) {
                        Text("개인정보 처리방침")
                            .foregroundColor(Color.blue)
                    }
                }
                Button(action: {
                    if let url = URL(string: "itms-beta://") {
                           UIApplication.shared.open(url, options: [:]) { success in
                               if !success {
                                   if let urlString = Bundle.main.object(
                                    forInfoDictionaryKey: "APPSTORE_URL") as? String,
                                      let appStoreURL = URL(string: urlString) {
                                       UIApplication.shared.open(appStoreURL)
                                   }
                               }
                           }
                       }
                }) {
                    VStack(alignment: .leading) {
                        Text("베타 테스트 참여")
                        Text("신규 기능을 빠르게 만나볼 수 있습니다")
                            .foregroundStyle(Color.gray)
                            .font(.caption)
                    }
                }
            }
            
            Section {
                Button {
                    router.push(Path.account)
                } label: {
                    Text("계정 연동")
                }
                Button(role: .destructive, action: {
                    viewModel.send(.setAlert(isPresented: true, type: .signOut))
                }) {
                    Text("로그아웃")
                }
            }
            
            HStack {
                Spacer()
                Button(role: .destructive, action: {
                    viewModel.send(.setAlert(isPresented: true, type: .deleteAuth))
                }) {
                    Text("회원 탈퇴")
                        .font(.headline)
                }
                Spacer()
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Path.self) { path in
            switch path {
            case .theme:
                ThemeView(
                    theme: Binding(
                        get: { viewModel.state.theme },
                        set: { viewModel.send(.setTheme($0)) }
                    )
                )
            case .pushNotification:
                PushNotificationSettingsView(
                    viewModel: PushNotificationSettingsViewModel(
                        fetchPushSettingsUseCase: container.resolve(FetchPushSettingsUseCase.self),
                        updatePushSettingsUseCase: container.resolve(UpdatePushSettingsUseCase.self)
                    )
                )
            case .account:
                AccountView(
                    viewModel: AccountViewModel(
                        fetchProvidersUseCase: container.resolve(FetchAuthProvidersUseCase.self),
                        linkProviderUseCase: container.resolve(LinkAuthProviderUseCase.self),
                        unlinkProviderUseCase: container.resolve(UnlinkAuthProviderUseCase.self)
                    )
                )
            }
        }
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

    private enum Path: Hashable {
        case theme, pushNotification, account
    }

    @ViewBuilder
    private var alertButtons: some View {
        switch viewModel.state.alertType {
        case .signOut:
            Button("취소", role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
            Button("확인", role: .destructive) {
                viewModel.send(.tapSignOutButton)
            }
        case .deleteAuth:
            Button("취소", role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
            Button("탈퇴", role: .destructive) {
                viewModel.send(.tapDeleteAuthButton)
            }
        case .removeCache:
            Button("취소", role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
            Button("확인", role: .destructive) {
                viewModel.send(.confirmRemoveCache)
            }
        case .error, .none:
            Button("확인", role: .cancel) {
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
