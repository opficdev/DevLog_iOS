//
//  AccountView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @State var viewModel: AccountViewModel

    var body: some View {
        List {
            Section("현재 계정") {
                HStack {
                    if let provider = viewModel.state.currentProvider {
                        providerContent(provider)
                    }
                }
            }
            Section("소셜 계정") {
                let providers = AuthProvider.allCases.filter { $0 != viewModel.state.currentProvider }
                ForEach(providers, id: \.self) { provider in
                    let isConnected = viewModel.state.connectedProviders.contains(provider)
                    HStack {
                        providerContent(provider)
                        Spacer()
                        Button {
                            if isConnected {
                                viewModel.send(.unlinkFromProvider(provider))
                            } else {
                                viewModel.send(.linkWithProvider(provider))
                            }
                        } label: {
                            Text(isConnected ? "연결 해제" : "연결")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isConnected ? Color.red : .blue)
                                .clipShape(.capsule)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .scrollDisabled(true)
        .listStyle(.insetGrouped)
        .navigationTitle("계정 연동")
        .onAppear {
            viewModel.send(.onAppear)
        }
        .alert(viewModel.state.alertTitle, isPresented: Binding(
            get: { viewModel.state.showAlert },
            set: { viewModel.send(.setAlert(isPresented: $0)) }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
        }
        .toast(isPresented: Binding(
            get: { viewModel.state.showToast },
            set: { viewModel.send(.setToast(isPresented: $0)) }
        )) {
            Text(viewModel.state.toastMessage)
        }
        .overlay {
            if viewModel.state.isLoading {
                LoadingView()
            }
        }
    }
    
    private func formattedProviderName(_ provider: AuthProvider) -> String {
        let rawValue = provider.rawValue
        let providerPrefix = rawValue.prefix(1).uppercased()
        let providerSuffix = rawValue.dropFirst().prefix(while: { $0 != "." })
        return providerPrefix + providerSuffix
    }

    @ViewBuilder
    private func providerContent(_ provider: AuthProvider) -> some View {
        Image(formattedProviderName(provider))
            .resizable()
            .scaledToFit()
            .frame(width: UIFont.labelFontSize)
        Text(formattedProviderName(provider))
    }
}
