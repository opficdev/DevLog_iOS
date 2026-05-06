//
//  LoginView.swift
//  DevLog
//
//  Created by opfic on 12/30/24.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.sceneWidth) var sceneWidth
    @State var viewModel: LoginViewModel

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Image("Primary")
                    .resizable()
                    .scaledToFit()
                    .frame(width: sceneWidth / 5)
                Spacer()
                VStack(spacing: 20) {
                    LoginButton(logo: Image("Google"), text: String(localized: "login_google_sign_in")) {
                        viewModel.send(.tapSignInButton(.google))
                    }
                    
                    LoginButton(logo: Image("Github"), text: String(localized: "login_github_sign_in")) {
                        viewModel.send(.tapSignInButton(.github))
                    }
                        
                    LoginButton(logo: Image("Apple"), text: String(localized: "login_apple_sign_in")) {
                        viewModel.send(.tapSignInButton(.apple))
                    }
                }
                .padding(.bottom, 30)
                Text(String(localized: "login_terms_notice"))
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
            }
            if viewModel.state.isLoading {
                LoadingView()
            }
        }
        .alert(viewModel.state.alertTitle, isPresented: Binding(
            get: { viewModel.state.showAlert },
            set: { viewModel.send(.setAlert($0)) }
        )) {
            Button(String(localized: "common_close"), role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
        }
    }
}
