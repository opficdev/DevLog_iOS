//
//  LoginView.swift
//  DevLogPresentation
//
//  Created by opfic on 12/30/24.
//

import SwiftUI
import ComposableArchitecture

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.sceneWidth) var sceneWidth
    @Bindable var store: StoreOf<LoginFeature>

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
                        store.send(.tapSignInButton(.google))
                    }
                    
                    LoginButton(logo: Image("Github"), text: String(localized: "login_github_sign_in")) {
                        store.send(.tapSignInButton(.github))
                    }
                        
                    LoginButton(logo: Image("Apple"), text: String(localized: "login_apple_sign_in")) {
                        store.send(.tapSignInButton(.apple))
                    }
                }
                .padding(.bottom, 30)
                Text(String(localized: "login_terms_notice"))
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
            }
            if store.isLoading {
                LoadingView()
            }
        }
        .alert(store.alertTitle, isPresented: $store.showAlert) {
            Button(String(localized: "common_close"), role: .cancel) { }
        } message: {
            Text(store.alertMessage)
        }
    }
}
