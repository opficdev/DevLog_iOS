//
//  RootView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI

struct RootView: View {
    @Environment(\.diContainer) var container: DIContainer
    @StateObject var viewModel: RootViewModel

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            if let signIn = viewModel.state.signIn {
                if signIn && !viewModel.state.isFirstLaunch {
                    MainView()
                } else {
                    LoginView(viewModel: LoginViewModel(
                        signInUseCase: container.resolve(SignInUseCase.self),
                        signOutUseCase: container.resolve(SignOutUseCase.self),
                        sessionUseCase: container.resolve(AuthSessionUseCase.self))
                    )
                    .onAppear {
                        if viewModel.state.isFirstLaunch {
                            viewModel.send(.setFirstLaunch(false))
                            viewModel.send(.signOutAuto)
                        }
                    }
                }
            } else {
                Color.clear.onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if viewModel.state.signIn == nil {
                            viewModel.send(.setFirstLaunch(true))
                            viewModel.send(.signOutAuto)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(viewModel.state.theme.colorScheme)
        .alert(viewModel.state.alertTitle, isPresented: Binding(
            get: { viewModel.state.showAlert },
            set: { viewModel.send(.setAlert($0)) }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
        }
        .onChange(of: viewModel.state.isFirstLaunch) { newValue in
            if newValue {
                viewModel.send(.setFirstLaunch(false))
                viewModel.send(.signOutAuto)
            }
        }
    }
}
