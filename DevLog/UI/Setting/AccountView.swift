//
//  AccountView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @StateObject var viewModel: AccountViewModel

    var body: some View {
        List {
            Section("현재 계정") {
                HStack {
                    if let provider = viewModel.state.currentProvider {
                        let formattedProvider = formattedProviderName(provider)
                        Image(formattedProvider)
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIFont.labelFontSize)
                        Text(formattedProvider)
                    }
                }
            }
            Section("연동된 계정") {
                ForEach(viewModel.state.connectedProviders, id: \.self) { provider in
                    HStack {
                        let formattedProvider = formattedProviderName(provider)
                        Image(formattedProvider)
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIFont.labelFontSize)
                        Text(formattedProvider)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive, action: {
                            viewModel.send(.unlinkFromProvider(provider))
                        }) {
                            Label("계정 삭제", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("계정 연동")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("새 계정 연동", systemImage: "plus") {
                    ForEach(viewModel.state.disconnectedProviders, id: \.self) { provider in
                        Button(action: {
                            viewModel.send(.linkWithProvider(provider))
                        }) {
                            HStack {
                                let formattedProvider = formattedProviderName(provider)
                                Image(formattedProvider)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: UIFont.systemFontSize, height: UIFont.systemFontSize)
                                Text(formattedProvider)
                            }
                        }
                    }
                }
            }
        }
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
}
