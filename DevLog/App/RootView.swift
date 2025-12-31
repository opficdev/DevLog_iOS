//
//  RootView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI

struct RootView: View {
    @AppStorage("isFirstLaunch") var isFirstLaunch = true   // 앱을 최초 설치했을 때 기존 로그인 세션이 남아있으면 자동 로그인됨을 막음
    @StateObject var viewModel: LoginViewModel

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            if let signIn = viewModel.state.signIn {
                if signIn && !isFirstLaunch {
                    MainView()
                } else {
                    LoginView(viewModel: viewModel)
                        .onAppear {
                            if isFirstLaunch {
                                isFirstLaunch = false
                                viewModel.send(.signOutAuto)
                            }
                        }
                }
            } else {
                Color.clear.onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if viewModel.state.signIn == nil {
                            isFirstLaunch = true
                            viewModel.send(.signOutAuto)
                        }
                    }
                }
            }
            if viewModel.state.isLoading {
                LoadingView()
            }
        }
        .alert("네트워크 문제", isPresented: Binding(
            get: { viewModel.state.showToast },
            set: { _, _ in }
        )) {
            Button(role: .cancel, action: {
                viewModel.send(.tapCloseToast)
            }) {
                Text("확인")
            }
        } message: {
            Text(viewModel.state.toastMessage)
        }
        .onChange(of: isFirstLaunch) { _ in
            if isFirstLaunch {
                isFirstLaunch = false
                viewModel.send(.signOutAuto)
            }
        }
    }
}
