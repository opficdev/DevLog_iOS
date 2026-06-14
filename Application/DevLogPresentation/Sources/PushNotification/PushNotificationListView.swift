//
//  PushNotificationListView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import ComposableArchitecture
import DevLogCore

struct PushNotificationListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .body) private var headerHeight = 41
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = 34
    @State private var headerOffset: CGFloat = 0
    @State private var isScrollTrackingEnabled = false
    @State private var store: StoreOf<PushNotificationListFeature>
    let coordinator: PushNotificationListViewCoordinator
    let isCompactLayout: Bool
    init(
        coordinator: PushNotificationListViewCoordinator,
        isCompactLayout: Bool
    ) {
        self.coordinator = coordinator
        self.isCompactLayout = isCompactLayout
        self._store = State(initialValue: coordinator.store)
    }

    var body: some View {
        NavigationStack {
            notificationList
                .background(Color(.systemGroupedBackground))
                .background(NavigationBarConfigurator(alwaysVisible: true))
                .onScrollOffsetChange { offset in
                    guard isScrollTrackingEnabled else { return }
                    headerOffset = max(0, -offset)
                }
                .safeAreaInset(edge: .top) { safeAreaHeader }
                .refreshable { store.send(.fetchNotifications) }
                .navigationTitle(String(localized: "nav_push_notifications"))
                .listStyle(.plain)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: sheetStore) { store in
            sheetContent(store)
        }
        .task(id: isCompactLayout) {
            store.send(.syncSheetPresentation(isCompactLayout: isCompactLayout))
        }
        .onChange(of: store.selectedTodoId?.id, initial: true) {
            store.send(.syncSheetPresentation(isCompactLayout: isCompactLayout))
        }
        .overlay {
            if store.isLoading {
                LoadingView()
            }
        }
    }

    @ViewBuilder
    private var notificationList: some View {
        let notifications = store.notifications.filter { !$0.isHidden }
        if notifications.isEmpty {
            Text(String(localized: "push_notifications_empty"))
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(
                Array(zip(notifications.indices, notifications)),
                id: \.1.id
            ) { index, notification in
                notificationListRow(notification, index: index, notifications: notifications)
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
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
                store.send(.selectNotification(notification.id))
            } label: {
                notificationRowContent(notification, index: index, notifications: notifications)
            }
            .buttonStyle(.plain)
        } else {
            notificationRowContent(notification, index: index, notifications: notifications)
                .onTapGesture {
                    store.send(.selectNotification(notification.id))
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    store.send(.selectNotification(notification.id))
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
            isSelected: !isCompactLayout && store.selectedNotificationId == notification.id
        )
        .onAppear {
            let lastId = notifications.last?.id
            if notification.id == lastId, store.hasMore {
                store.send(.loadNextPage)
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
                Color(.systemGroupedBackground)
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
            if 0 < store.appliedFilterCount {
                Menu {
                    Text(
                        String.localizedStringWithFormat(
                            String(localized: "push_filters_applied_format"),
                            Int64(store.appliedFilterCount)
                        )
                    )
                    Button(role: .destructive) {
                        store.send(.resetFilters)
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
                    store.send(.toggleSortOption)
                }
            } label: {
                let condition = store.query.sortOrder == .oldest
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "push_sort_format"),
                        store.query.sortOrder.title
                    )
                )
                .foregroundStyle(condition ? .white : Color(.label))
                .adaptiveButtonStyle(color: condition ? .blue : .clear)
            }

            Menu {
                Picker(selection: $store.query.timeFilter) {
                    ForEach(PushNotificationQuery.TimeFilter.availableOptions, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                } label: {
                    Text(String(localized: "push_period"))
                }
            } label: {
                let condition = store.query.timeFilter == .none
                HStack {
                    Text(String(localized: "push_period"))
                    Image(systemName: "chevron.down")
                }
                .foregroundStyle(condition ? Color(.label) : .white)
                .adaptiveButtonStyle(color: condition ? .clear : .blue)
            }

            Button {
                DispatchQueue.main.async {
                    store.send(.toggleUnreadOnly)
                }
            } label: {
                let condition = store.query.unreadOnly
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

        return Text("\(store.appliedFilterCount)")
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
                store.send(.toggleRead(item))
            } label: {
                Image(systemName: "checkmark.circle\(item.isRead ? ".badge.xmark" : "")")
                    .tint(.blue)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(
                role: .destructive,
                action: {
                    store.send(.deleteNotification(item))
                    presentDeleteNotificationToast(item.id)
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

    @ViewBuilder
    private func sheetContent(
        _ sheetStore: Store<PushNotificationListFeature.SheetState, PushNotificationListFeature.Action.Sheet>
    ) -> some View {
        NavigationStack {
            TodoDetailView(store: coordinator.makeTodoDetailStore(todoId: sheetStore.todoId))
                .id(sheetStore.todoId)
                .toolbar {
                    ToolbarLeadingButton {
                        sheetStore.send(.tapCloseButton)
                    }
                }
        }
        .background(Color(.systemGroupedBackground))
        .presentationDragIndicator(.visible)
    }

    private var sheetStore: Binding<
        Store<PushNotificationListFeature.SheetState,
              PushNotificationListFeature.Action.Sheet>?> {
        if isCompactLayout {
            $store.scope(state: \.sheet, action: \.sheet)
        } else {
            .constant(nil)
        }
    }

    private func presentDeleteNotificationToast(_ notificationId: String) {
        ToastPresenter.present(
            message: String(localized: "common_undo"),
            systemImage: "arrow.uturn.left",
            duration: 5,
            font: .caption,
            multilineTextAlignment: .center,
            lineLimit: 3,
            action: {
                store.send(.undoDelete)
            },
            onDismiss: {
                store.send(.finishDeleteToast(notificationId))
            }
        )
    }
}
