//
//  AccountView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import ComposableArchitecture
import DevLogDomain

struct AccountView: View {
    @Bindable var store: StoreOf<AccountFeature>

    var body: some View {
        List {
            Section(String(localized: "account_current_section")) {
                HStack {
                    if let provider = store.currentProvider {
                        providerContent(provider)
                    }
                }
            }
            Section(String(localized: "account_social_section")) {
                let providers = AuthProvider.allCases.filter { $0 != store.currentProvider }
                ForEach(providers, id: \.self) { provider in
                    let isConnected = store.connectedProviders.contains(provider)
                    HStack {
                        providerContent(provider)
                        Spacer()
                        Button {
                            if isConnected {
                                store.send(.unlinkFromProvider(provider))
                            } else {
                                store.send(.linkWithProvider(provider))
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
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
        .overlay {
            if store.isLoading {
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
