//
//  SettingView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("theme") var theme: SystemTheme = .automatic
    @Environment(\.diContainer) var container: DIContainer
    @StateObject var viewModel: SettingViewModel
    @EnvironmentObject var router: NavigationRouter

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
                        Text(viewModel.state.theme)
                            .foregroundStyle(Color.gray)
                    }
                }
                .onAppear {
                    viewModel.send(.setTheme(theme.localizedName))
                }

                Button {
                    router.push(Path.pushNotification)
                } label: {
                    Text("알림")
                        .foregroundStyle(Color.primary)
                }
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
                    viewModel.send(.setAlert(isPresented: true, type: .cancel))
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
                ThemeView()
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
        case .cancel:
            Button("취소", role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
            Button("탈퇴", role: .destructive) {
                viewModel.send(.tapDeleteAuthButton)
            }
        case .error, .none:
            Button("확인", role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
        }
    }
}
