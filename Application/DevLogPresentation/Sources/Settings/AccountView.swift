//
//  AccountView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import DevLogDomain

struct AccountView: View {
    @State var viewModel: AccountViewModel

    var body: some View {
        List {
            Section(String(localized: "account_current_section")) {
                HStack {
                    if let provider = viewModel.state.currentProvider {
                        providerContent(provider)
                    }
                }
            }
            Section(String(localized: "account_social_section")) {
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
                            Text(isConnected
                                 ? String(localized: "account_disconnect")
                                 : String(localized: "account_connect"))
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
        .navigationTitle(String(localized: "nav_account"))
        .onAppear {
            viewModel.send(.onAppear)
        }
        .alert(viewModel.state.alertTitle, isPresented: Binding(
            get: { viewModel.state.showAlert },
            set: { viewModel.send(.setAlert(isPresented: $0)) }
        )) {
            Button(String(localized: "common_close"), role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
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
