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
    @Environment(\.sceneWidth) private var sceneWidth
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.diContainer) private var container: DIContainer

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                Section {
                    if viewModel.displayedNotifications.isEmpty {
                        HStack {
                            Spacer()
                            Text("받은 알림이 없습니다.")
                                .foregroundStyle(Color.gray)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(viewModel.displayedNotifications, id: \.id) { notification in
                            Button {
                                viewModel.send(.tapNotification(notification))
                            } label: {
                                notificationRow(notification)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                if notification.id == viewModel.displayedNotifications.last?.id {
                                    viewModel.send(.loadNextPage)
                                }
                            }
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
            .sheet(item: Binding(
                get: { viewModel.state.selectedTodoID },
                set: { viewModel.send(.setSelectedTodoID($0)) }
            )) { item in
                VStack(spacing: 0) {
                    Spacer(minLength: 16)
                    TodoDetailView(viewModel: TodoDetailViewModel(
                        fetchUseCase: container.resolve(FetchTodoByIDUseCase.self),
                        upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                        todoID: item.id
                    ))
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
                    }
                    .adaptiveButtonStyle()
                }

                Button {
                    viewModel.send(.toggleSortOption)
                } label: {
                    Text("정렬: \(viewModel.state.query.sortOrder.title)")
                }
                .adaptiveButtonStyle(viewModel.state.query.sortOrder == .oldest ? .blue : .clear)

                Menu {
                    ForEach(PushNotificationQuery.TimeFilter.availableOptions, id: \.id) { option in
                        Button {
                            viewModel.send(.setTimeFilter(option))
                        } label: {
                            HStack {
                                Text(option.title)
                                Spacer()
                                if viewModel.state.query.timeFilter == option {
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
                .adaptiveButtonStyle(viewModel.state.query.timeFilter == .none ? .clear : .blue)

                Button {
                    viewModel.send(.toggleUnreadOnly)
                } label: {
                    Text("읽지 않음")
                }
                .adaptiveButtonStyle(viewModel.state.query.unreadOnly ? .blue : .clear)
            }
        }
        .scrollIndicators(.never)
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
    private func notificationRow(_ notification: PushNotification) -> some View {
        HStack {
            VStack {
                let todoKind = notification.todoKind
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
                    .opacity(notification.isRead ? 0 : 1)
            }

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
        .contentShape(.rect)
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
