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
    @StateObject var viewModel: LoginViewModel

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
                    LoginButton(logo: Image("Google"), text: "구글 계정으로 로그인") {
                        viewModel.send(.tapSignInButton(.google))
                    }
                    .frame(width: sceneWidth * 3 / 4, height: sceneWidth / 10)
                    
                    LoginButton(logo: Image("Github"), text: "깃헙 계정으로 로그인") {
                        viewModel.send(.tapSignInButton(.github))
                    }
                    .frame(width: sceneWidth * 3 / 4, height: sceneWidth / 10)
                        
                    LoginButton(logo: Image("Apple"), text: "애플 계정으로 로그인") {
                        viewModel.send(.tapSignInButton(.apple))
                    }
                    .frame(width: sceneWidth * 3 / 4, height: sceneWidth / 10)
                }
                .padding(.bottom, 30)
                Text("로그인하면 사용 약관 및 개인 정보 취급 방침에 동의하게 됩니다.")
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
            }
            if viewModel.state.isLoading {
                LoadingView()
            }
        }
    }
}
