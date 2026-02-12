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
                    let provider = viewModel.state.currentProvider
                    let formattedProvider = formattedProviderName(provider)
                    Image(formattedProvider)
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIFont.labelFontSize)
                    Text(formattedProvider)
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
        .onAppear {
            viewModel.send(.onAppear)
//            connectedProviders = viewModel.providers.filter { provider in
//                provider != viewModel.currentProvider
//            }
//            disconnectedProviders = ["google.com", "github.com", "apple.com"].filter { provider in
//                !viewModel.providers.contains(provider)
//            }
        }
//        .onChange(of: viewModel.providers) { newProviders in
//            connectedProviders = newProviders.filter { provider in
//                provider != viewModel.currentProvider
//            }
//            disconnectedProviders = ["google.com", "github.com", "apple.com"].filter { provider in
//                !newProviders.contains(provider)
//            }
//        }
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
        .alert(viewModel.state.alertTitle, isPresented: Binding(
            get: { viewModel.state.showAlert },
            set: { viewModel.send(.setAlert(isPresented: $0)) }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
        }
    }

    private func formattedProviderName(_ provider: String) -> String {
        // provider에서 첫번째 글자만 대문자로 바꾸고 .을 포함한 뒤는 다 제거 ex) google.com -> Google
        let providerPrefix = provider.prefix(1).uppercased()
        let providerSuffix = provider.dropFirst().prefix(while: { $0 != "." })
        return providerPrefix + providerSuffix
    }
}
