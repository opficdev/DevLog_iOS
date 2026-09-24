//
//  UserInfoCard.swift
//  ProfileTab
//
//  Created by opfic on 9/24/26.
//

import SwiftUI
import PresentationShared

struct UserInfoCard: View {
    @Bindable var store: StoreOf<ProfileFeature>
    @FocusState private var focused: Bool
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Group {
                    if let data = store.avatarImageData?.data,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.onPrimaryContainer, Color.primaryContainer)
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(.circle)
                .transaction { $0.animation = nil }

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.title2)
                        .bold()
                    Text(store.email)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: 0)
            }

            HStack {
                HStack {
                    Image(systemName: "face.smiling")
                    TextField(
                        text: $store.statusMessage
                    ) {
                        Text(String(localized: "profile_status_placeholder", bundle: PresentationResources.bundle))
                    }
                    .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight)
                    .focused($focused)
                    .disabled(!store.isNetworkConnected)

                    if !store.statusMessage.isEmpty,
                       store.showDoneButton {
                        Button {
                            store.send(.tapResetStatusMessageButton)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .foregroundStyle(Color.onPrimaryContainer)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primaryContainer)
                )
                if store.showDoneButton {
                    Button {
                        focused = false
                        store.send(.willUpdateStatusMessage)
                    } label: {
                        Text(String(localized: "profile_done", bundle: PresentationResources.bundle))
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .opacity(store.isNetworkConnected ? 1 : 0.7)
        }
        .padding(16)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 16))
        .onChange(of: isSelected, initial: true) { _, isSelected in
            if !isSelected {
                focused = false
            }
        }
        .onChange(of: focused) { _, focused in
            store.send(.updateStatusTextFieldFocus(focused), animation: .default)
        }
    }
}
