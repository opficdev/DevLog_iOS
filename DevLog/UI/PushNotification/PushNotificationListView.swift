//
//  PushNotificationListView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct PushNotificationListView: View {
    @State private var router = NavigationRouter()
    @State var viewModel: PushNotificationListViewModel
    @Environment(\.sceneWidth) private var sceneWidth
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.diContainer) private var container: DIContainer
    @State private var headerOffset: CGFloat = 0
    @State private var isScrollTrackingEnabled = false

    var body: some View {
        NavigationStack(path: $router.path) {
            notificationList
            .listStyle(.plain)
            .background(NavigationBarConfigurator(.secondarySystemBackground, alwaysVisible: true))
            .onScrollOffsetChange { offset in
                guard isScrollTrackingEnabled else { return }
                headerOffset = max(0, -offset)
            }
            .safeAreaInset(edge: .top) { safeAreaHeader }
            .background(Color(.secondarySystemBackground))
            .onAppear {
                viewModel.send(.fetchNotifications)
                headerOffset = 0
                isScrollTrackingEnabled = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isScrollTrackingEnabled = true
                }
            }
            .refreshable { viewModel.send(.fetchNotifications) }
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
            .sheet(item: Binding(
                get: { viewModel.state.selectedTodoID },
                set: { viewModel.send(.setSelectedTodoID($0)) }
            )) { item in
                NavigationStack {
                    TodoDetailView(viewModel: TodoDetailViewModel(
                        fetchUseCase: container.resolve(FetchTodoByIDUseCase.self),
                        upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                        todoID: item.id,
                        showEditButton: false
                    ))
                    .toolbar {
                        ToolbarLeadingButton {
                            viewModel.send(.setSelectedTodoID(nil))
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
    }

    private var notificationList: some View {
        List {
            Group {
                if viewModel.state.notifications.isEmpty {
                    HStack {
                        Spacer()
                        Text("받은 알림이 없습니다.")
                            .foregroundStyle(Color.gray)
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                } else {
                    let notifications = viewModel.state.notifications
                    ForEach(Array(zip(notifications.indices, notifications)), id: \.1.id) { idx, notification in
                        Button {
                            viewModel.send(.tapNotification(notification))
                        } label: {
                            notificationRow(notification)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            let lastID = viewModel.state.notifications.last?.id
                            if notification.id == lastID, viewModel.state.hasMore {
                                viewModel.send(.loadNextPage)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .overlay(alignment: .top) {
                            if #available(iOS 26.0, *) {
                                if idx == 0 {
                                    Divider()
                                        .padding(.horizontal, -16)
                                }
                            }
                        }
                    }
                }
            }
            .listSectionSeparator(.hidden, edges: .top)
            .listRowBackground(Color.clear)
        }
    }

    private var safeAreaHeader: some View {
        VStack(spacing: 4) {
            headerView
                .clipped()
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
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if 0 < viewModel.appliedFilterCount {
                    Menu {
                        Text("\(viewModel.appliedFilterCount)개 필터가 적용됨")
                        Button(role: .destructive) {
                            viewModel.send(.resetFilters)
                        } label: {
                            Text("모든 필터 지우기")
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
                    viewModel.send(.toggleSortOption)
                } label: {
                    let condition = viewModel.state.query.sortOrder == .oldest
                    Text("정렬: \(viewModel.state.query.sortOrder.title)")
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
                        Text("기간")
                    }
                } label: {
                    let condition = viewModel.state.query.timeFilter == .none
                    HStack {
                        Text("기간")
                        Image(systemName: "chevron.down")
                    }
                    .foregroundStyle(condition ? Color(.label) : .white)
                    .adaptiveButtonStyle(color: condition ? .clear : .blue)
                }

                Button {
                    viewModel.send(.toggleUnreadOnly)
                } label: {
                    let condition = viewModel.state.query.unreadOnly
                    Text("읽지 않음")
                        .foregroundStyle(condition ? .white : Color(.label))
                        .adaptiveButtonStyle(color: condition ? .blue : .clear)
                }
            }
            .frame(height: 36)
        }
        .scrollIndicators(.never)
        .scrollDisabled(!isScrollTrackingEnabled)
        .contentMargins(.leading, 16, for: .scrollContent)
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
    private func notificationRow(_ item: PushNotificationItem) -> some View {
        HStack {
            VStack {
                let todoKind = item.todoKind
                RoundedRectangle(cornerRadius: 8)
                    .fill(todoKind.color)
                    .frame(width: sceneWidth * 0.08, height: sceneWidth * 0.08)
                    .overlay {
                        Image(systemName: todoKind.symbolName)
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
                    .lineLimit(1)
                Text(item.body)
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                Text(timeAgoText(from: item.receivedAt, now: context.date))
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
            }
        }
        .padding(.vertical, 5)
        .contentShape(.rect)
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
