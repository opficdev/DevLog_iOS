//
//  PushNotificationListView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct PushNotificationListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.diContainer) private var container: DIContainer
    @ScaledMetric(relativeTo: .body) private var headerHeight = 41
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = 34
    @State var viewModel: PushNotificationListViewModel
    @State private var headerOffset: CGFloat = 0
    @State private var isScrollTrackingEnabled = false
    @Binding var todoIdToPresent: TodoIdItem?
    let isCompactLayout: Bool

    var body: some View {
        NavigationStack {
            notificationList
                .background(NavigationBarConfigurator(.secondarySystemBackground, alwaysVisible: true))
                .onScrollOffsetChange { offset in
                    guard isScrollTrackingEnabled else { return }
                    headerOffset = max(0, -offset)
                }
                .safeAreaInset(edge: .top) { safeAreaHeader }
                .onAppear { viewModel.send(.fetchNotifications) }
                .refreshable { viewModel.send(.fetchNotifications) }
                .navigationTitle(String(localized: "nav_push_notifications"))
        }
        .listStyle(.sidebar)
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .alert(
            "",
            isPresented: Binding(
                get: { viewModel.state.showAlert },
                set: { viewModel.send(.setAlert(isPresented: $0)) }
        )) {
            Button(String(localized: "common_close"), role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
        }
        .toast(
            isPresented: Binding(
                get: { viewModel.state.showToast },
                set: { viewModel.send(.setToast(isPresented: $0)) }),
            duration: 5,
            action: { viewModel.send(.undoDelete) }
        ) {
            Label(viewModel.state.toastMessage, systemImage: "arrow.uturn.left")
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .sheet(item: Binding(
            get: { isCompactLayout ? todoIdToPresent : nil },
            set: { item in
                if item == nil {
                    selectNotification(nil)
                }
            }
        )) { item in
            NavigationStack {
                TodoDetailView(viewModel: TodoDetailViewModel(
                    fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
                    fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                    upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                    todoId: item.id,
                    showEditButton: false
                ))
                .id(item.id)
                .toolbar {
                    ToolbarLeadingButton {
                        selectNotification(nil)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .presentationDragIndicator(.visible)
        }
        .overlay {
            if viewModel.state.isLoading {
                LoadingView()
            }
        }
    }

    @ViewBuilder
    private var notificationList: some View {
        let notifications = viewModel.state.notifications.filter { !$0.isHidden }
        if notifications.isEmpty {
            HStack {
                Spacer()
                Text(String(localized: "push_notifications_empty"))
                    .foregroundStyle(Color.gray)
                Spacer()
            }
        } else {
            List(
                Array(zip(notifications.indices, notifications)),
                id: \.1.id
            ) { index, notification in
                notificationListRow(notification, index: index, notifications: notifications)
                .listRowInsets(EdgeInsets())
                .listSectionSeparator(.hidden, edges: .top)
                .listRowBackground(Color.clear)
            }
        }
    }

    @ViewBuilder
    private func notificationListRow(
        _ notification: PushNotificationItem,
        index: Int,
        notifications: [PushNotificationItem]
    ) -> some View {
        if isCompactLayout {
            Button {
                selectNotification(notification.id)
            } label: {
                notificationRowContent(notification, index: index, notifications: notifications)
            }
            .buttonStyle(.plain)
        } else {
            notificationRowContent(notification, index: index, notifications: notifications)
                .onTapGesture {
                    selectNotification(notification.id)
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    selectNotification(notification.id)
                }
        }
    }

    private func notificationRowContent(
        _ notification: PushNotificationItem,
        index: Int,
        notifications: [PushNotificationItem]
    ) -> some View {
        notificationRow(
            notification,
            isSelected: !isCompactLayout && viewModel.state.selectedNotificationId == notification.id
        )
        .onAppear {
            let lastId = notifications.last?.id
            if notification.id == lastId, viewModel.state.hasMore {
                viewModel.send(.loadNextPage)
            }
        }
        .overlay(alignment: .top) {
            if #available(iOS 26.0, *) {
                if index == 0 {
                    Divider()
                        .padding(.horizontal, -16)
                }
            }
        }
    }

    private var safeAreaHeader: some View {
        VStack(spacing: 4) {
            headerView
            if #unavailable(iOS 26) {
                Divider()
                    .padding(.horizontal, -16)
            }
        }
        .background {
            if #available(iOS 26.0, *) {
                Color.clear
            } else {
                Color(.secondarySystemBackground)
            }
        }
        .offset(y: headerOffset)
    }

    private var headerView: some View {
        Group {
            if #available(iOS 18, *) {
                ScrollView(.horizontal) { headerContent }
                .scrollIndicators(.never)
                .scrollDisabled(!isScrollTrackingEnabled)
                .contentMargins(.leading, 16, for: .scrollContent)
            } else {
                headerContent
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: headerHeight)
        .onAppear {
            headerOffset = 0
            isScrollTrackingEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isScrollTrackingEnabled = true
            }
        }
    }

    private var headerContent: some View {
        HStack(spacing: 8) {
            if 0 < viewModel.appliedFilterCount {
                Menu {
                    Text(
                        String.localizedStringWithFormat(
                            String(localized: "push_filters_applied_format"),
                            Int64(viewModel.appliedFilterCount)
                        )
                    )
                    Button(role: .destructive) {
                        viewModel.send(.resetFilters)
                    } label: {
                        Text(String(localized: "push_clear_all_filters"))
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease")
                        filterBadge
                    }
                    .adaptiveButtonStyle()
                }
            }

            Button {
                DispatchQueue.main.async {
                    viewModel.send(.toggleSortOption)
                }
            } label: {
                let condition = viewModel.state.query.sortOrder == .oldest
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "push_sort_format"),
                        viewModel.state.query.sortOrder.title
                    )
                )
                .foregroundStyle(condition ? .white : Color(.label))
                .adaptiveButtonStyle(color: condition ? .blue : .clear)
            }

            Menu {
                Picker(selection: Binding(
                    get: { viewModel.state.query.timeFilter },
                    set: { viewModel.send(.setTimeFilter($0)) }
                )) {
                    ForEach(PushNotificationQuery.TimeFilter.availableOptions, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                } label: {
                    Text(String(localized: "push_period"))
                }
            } label: {
                let condition = viewModel.state.query.timeFilter == .none
                HStack {
                    Text(String(localized: "push_period"))
                    Image(systemName: "chevron.down")
                }
                .foregroundStyle(condition ? Color(.label) : .white)
                .adaptiveButtonStyle(color: condition ? .clear : .blue)
            }

            Button {
                DispatchQueue.main.async {
                    viewModel.send(.toggleUnreadOnly)
                }
            } label: {
                let condition = viewModel.state.query.unreadOnly
                Text(String(localized: "push_unread"))
                    .foregroundStyle(condition ? .white : Color(.label))
                    .adaptiveButtonStyle(color: condition ? .blue : .clear)
            }
        }
    }

    private var filterBadge: some View {
        let isDark = colorScheme == .dark
        let blue = Color(uiColor: .systemBlue)  //  흰 배경에 따른 청록색화 방지
        let textColor: Color = isDark ? blue : .white
        let backgroundColor: Color = isDark ? .white : blue

        return Text("\(viewModel.appliedFilterCount)")
            .font(.caption2.weight(.bold))
            .foregroundColor(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: 20, height: 20)
            .background(Circle().fill(backgroundColor))
    }

    // swiftlint:disable function_body_length
    private func notificationRow(
        _ item: PushNotificationItem,
        isSelected: Bool
    ) -> some View {
        HStack {
            VStack {
                let todoCategoryItem = TodoCategoryItem(from: item.todoCategory)
                RoundedRectangle(cornerRadius: 8)
                    .fill(todoCategoryItem.color)
                    .frame(width: labelWidth, height: labelWidth)
                    .overlay {
                        Image(systemName: todoCategoryItem.symbolName)
                            .foregroundStyle(Color.white)
                            .font(.title3)
                    }
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .opacity(item.isRead ? 0 : 1)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(isSelected ? Color.white : Color(.label))
                    .lineLimit(1)
                Text(item.body)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? Color.white : .gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                Text(timeAgoText(from: item.receivedAt, now: context.date))
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.white : .gray)
            }
        }
        .padding(8)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : .clear)
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.send(.toggleRead(item))
            } label: {
                Image(systemName: "checkmark.circle\(item.isRead ? ".badge.xmark" : "")")
                    .tint(.blue)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(
                role: .destructive,
                action: {
                    viewModel.send(.deleteNotification(item))
                }
            ) {
                Image(systemName: "trash")
            }
        }
    }
    // swiftlint:enable function_body_length

    private func timeAgoText(from date: Date, now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(date))

        if seconds < 60 {
            return String.localizedStringWithFormat(
                String(localized: "push_time_seconds_ago_format"),
                Int64(max(0, seconds))
            )
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return String.localizedStringWithFormat(
                String(localized: "push_time_minutes_ago_format"),
                Int64(minutes)
            )
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return String.localizedStringWithFormat(
                String(localized: "push_time_hours_ago_format"),
                Int64(hours)
            )
        } else {
            let days = seconds / 86400
            return String.localizedStringWithFormat(
                String(localized: "push_time_days_ago_format"),
                Int64(days)
            )
        }
    }

    private func selectNotification(_ notificationId: String?) {
        viewModel.send(.selectNotification(notificationId))
        todoIdToPresent = viewModel.state.selectedTodoId
    }
}
