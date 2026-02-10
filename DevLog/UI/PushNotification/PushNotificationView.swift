//
//  NotificationView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct PushNotificationView: View {
    @StateObject private var router = NavigationRouter()
    @StateObject var viewModel: PushNotificationViewModel

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack {
                if viewModel.state.notifications.isEmpty {
                    Spacer()
                    Text("작성된 알림이 없습니다.")
                        .foregroundStyle(Color.gray)
                    Spacer()
                } else {
                    List(viewModel.state.notifications, id: \.id) { notification in
                        notificationRow(notification)
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color(.secondarySystemBackground))
            .navigationTitle("받은 푸시 알람")
            .alert(
                "",
                isPresented: Binding(
                    get: { viewModel.state.showAlert },
                    set: { viewModel.send(.setAlert(isPresented: $0)) }
            )) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(viewModel.state.alertMessage)
            }
            .toast(
                isPresented: Binding(
                    get: { viewModel.state.showToast },
                    set: { viewModel.send(.setToast(isPresented: $0)) }),
                duration: 5,
                action: { viewModel.send(.undoDelete) },
                onDismiss: { viewModel.send(.confirmDelete) }
            ) {
                Label(viewModel.state.toastMessage, systemImage: "arrow.uturn.left")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .onAppear {
                viewModel.send(.fetchNotifications)
            }
        }
    }

    private func notificationRow(_ notification: PushNotification) -> some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .opacity(notification.isRead ? 0 : 1)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(notification.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                Text(timeAgoText(from: notification.receivedAt, now: context.date))
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
            }
        }
        .padding(.vertical, 5)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing) {
            Button(
                role: .destructive,
                action: {
                    viewModel.send(.deleteNotification(notification))
                }
            ) {
                Image(systemName: "trash")
            }
        }
    }
    
    private func timeAgoText(from date: Date, now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        
        if seconds < 60 {
            return "\(max(0, seconds))초 전"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)분 전"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)시간 전"
        } else {
            let days = seconds / 86400
            return "\(days)일 전"
        }
    }
}
