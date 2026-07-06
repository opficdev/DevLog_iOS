//
//  LoginView.swift
//  Entry
//
//  Created by opfic on 12/30/24.
//

import SwiftUI
import PresentationShared
import Domain

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.sceneWidth) var sceneWidth
    @State private var store: StoreOf<LoginFeature>

    init(signInUseCase: SignInUseCase) {
        self._store = State(initialValue: Store(
            initialState: LoginFeature.State()
        ) {
            LoginFeature()
        } withDependencies: {
            $0.signInUseCase = signInUseCase
        })
    }

    var body: some View {
        VStack {
            Spacer()
            Image("Primary")
                .resizable()
                .scaledToFit()
                .frame(width: sceneWidth / 5)
            Spacer()
            VStack(spacing: 20) {
                signInButton(
                    provider: .google,
                    logo: Image("Google"),
                    text: String(localized: "login_google_sign_in")
                )

                signInButton(
                    provider: .github,
                    logo: Image("Github"),
                    text: String(localized: "login_github_sign_in")
                )

                signInButton(
                    provider: .apple,
                    logo: Image("Apple"),
                    text: String(localized: "login_apple_sign_in")
                )
            }
            .padding(.bottom, 30)
            Text(String(localized: "login_terms_notice"))
                .font(.caption2)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.vertical)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    private func signInButton(
        provider: AuthProvider,
        logo: Image,
        text: String
    ) -> some View {
        LoginButton(
            logo: logo,
            text: text,
            showsProgressView: store.activeSignInProvider == provider
        ) {
            store.send(.tapSignInButton(provider))
        }
        .disabled(store.isLoading)
        .opacity(store.isLoading ? 0.5 : 1)
    }
}
