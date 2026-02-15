//
//  PushNotificationView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct PushNotificationView: View {
    @StateObject private var router = NavigationRouter()
    @StateObject var viewModel: PushNotificationViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var previousStandardAppearance: UINavigationBarAppearance?
    @State private var previousScrollEdgeAppearance: UINavigationBarAppearance?
    @State private var sortOption: SortOption = .latest
    @State private var timeFilter: TimeFilter = .none
    @State private var showUnreadOnly: Bool = false

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                Section {
                    if displayedNotifications.isEmpty {
                        HStack {
                            Spacer()
                            Text("받은 알림이 없습니다.")
                                .foregroundStyle(Color.gray)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(displayedNotifications, id: \.id) { notification in
                            notificationRow(notification)
                        }
                    }
                } header: {
                    headerView
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .background(Color(.secondarySystemBackground))
            .onAppear { viewModel.send(.fetchNotifications) }
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
        }
    }

    private var headerView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if 0 < appliedFilterCount {
                    Menu {
                        Text("\(appliedFilterCount)개 필터가 적용됨")
                        Button(role: .destructive) {
                            resetFilters()
                        } label: {
                            Text("모든 필터 지우기")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease")
                            filterBadge
                        }
                    }
                    .adaptiveButtonStyle()
                }

                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.title)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .tint(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } label: {
                    Text("정렬")
                }
                .adaptiveButtonStyle()

                Menu {
                    ForEach(TimeFilter.availableOptions, id: \.id) { option in
                        Button {
                            timeFilter = option
                        } label: {
                            HStack {
                                Text(option.title)
                                Spacer()
                                if timeFilter == option {
                                    Image(systemName: "checkmark")
                                        .tint(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } label: {
                    Text("기간")
                }
                .adaptiveButtonStyle()

                Button {
                    showUnreadOnly.toggle()
                } label: {
                    Text("읽지 않음")
                }
                .adaptiveButtonStyle(showUnreadOnly ? .blue : .clear)
            }
        }
        .scrollIndicators(.never)
    }

    private var displayedNotifications: [PushNotification] {
        var items = viewModel.state.notifications

        if showUnreadOnly {
            items = items.filter { $0.isRead == false }
        }

        if case let .hours(value) = timeFilter {
            let threshold = Date().addingTimeInterval(-Double(value) * 3600.0)
            items = items.filter { $0.receivedAt >= threshold }
        } else if case let .days(value) = timeFilter {
            let threshold = Date().addingTimeInterval(-Double(value) * 86400.0)
            items = items.filter { $0.receivedAt >= threshold }
        }

        switch sortOption {
        case .latest:
            return items.sorted { $0.receivedAt > $1.receivedAt }
        case .oldest:
            return items.sorted { $0.receivedAt < $1.receivedAt }
        }
    }

    private var appliedFilterCount: Int {
        var count = 0
        if sortOption != .latest { count += 1 }
        if timeFilter != .none { count += 1 }
        if showUnreadOnly { count += 1 }
        return count
    }

    private var filterBadge: some View {
        let isDark = colorScheme == .dark
        let blue = Color(uiColor: .systemBlue)  //  흰 배경에 따른 청록색화 방지
        let textColor: Color = isDark ? blue : .white
        let backgroundColor: Color = isDark ? .white : blue

        return Text("\(appliedFilterCount)")
            .font(.caption2.weight(.bold))
            .foregroundColor(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: 20, height: 20)
            .background(Circle().fill(backgroundColor))
    }

    private func resetFilters() {
        sortOption = .latest
        timeFilter = .none
        showUnreadOnly = false
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
        .swipeActions(edge: .leading) {
            Button {
                viewModel.send(.toggleRead(notification))
            } label: {
                Image(systemName: "checkmark.circle\(notification.isRead ? ".badge.xmark" : "")")
                    .tint(.blue)
            }
        }
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

    private enum SortOption: CaseIterable {
        case latest
        case oldest

        var title: String {
            switch self {
            case .latest: return "최신 순"
            case .oldest: return "예전 순"
            }
        }
    }

    private enum TimeFilter: Equatable {
        case none
        case hours(Int)
        case days(Int)

        var id: String {
            switch self {
            case .none: return "none"
            case .hours(let value): return "hours-\(value)"
            case .days(let value): return "days-\(value)"
            }
        }

        var title: String {
            switch self {
            case .none:
                return "전체"
            case .hours(let value):
                return "최근 \(value)시간"
            case .days(let value):
                return "최근 \(value)일"
            }
        }

        static var availableOptions: [TimeFilter] {[
                .none,
                .hours(1),
                .hours(6),
                .hours(24),
                .days(3),
                .days(7)
            ]
        }
    }
}
