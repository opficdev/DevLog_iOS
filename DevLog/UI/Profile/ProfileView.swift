//
//  ProfileView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    @FocusState private var focusedOnStatusMsg: Bool
    @State private var showDoneBtn: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        CacheableImage(viewModel.state.avatarURL)
                            .frame(width: 60, height: 60)
                            .cornerRadius(30)
                            .foregroundStyle(Color.gray)

                        VStack(alignment: .leading) {
                            Text(viewModel.state.name)
                                .font(.title2)
                                .bold()
                            Text(viewModel.state.email)
                                .font(.caption2)
                                .foregroundStyle(Color.gray)
                        }
                    }
                    HStack {
                        HStack {
                            Image(systemName: "face.smiling")
                            TextField(text: Binding(
                                get: { viewModel.state.statusMessage },
                                set: { viewModel.send(.didUpdateStatusMessage($0)) })
                            ) {
                                HStack {
                                    Text("상태 설정")
                                }
                            }
                            .focused($focusedOnStatusMsg)
                            
                            if viewModel.state.resetButtonEnabled {
                                Button(action: {
                                    viewModel.send(.didTapResetStatusMessageButton)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .foregroundStyle(Color.gray)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemGray5))
                        )
                        if viewModel.state.showDoneButton {
                            Button(action: {
                                focusedOnStatusMsg = false
                                viewModel.send(.willUpdateStatusMessage)
                            }) {
                                Text("완료")
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 0) {
                        NavigationLink(destination: SettingView(viewModel: SettingViewModel())) {
                            Image(systemName: "gearshape")
                        }
                        Button(action: {
                            // TODO: 기능 추가 생각해야함
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .onChange(of: focusedOnStatusMsg) { newValue in
                withAnimation {
                    showDoneBtn = newValue
                }
            }
            .alert("", isPresented: Binding(
                get: { viewModel.state.showToast },
                set: { _, _ in }
            )) {
                Button("확인") {
                    viewModel.send(.didDismissToast)
                }
            } message: {
                Text(viewModel.state.toastMessage)
            }
        }
    }
}
