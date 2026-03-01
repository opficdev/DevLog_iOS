//
//  ProfileView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import MarkdownUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    @StateObject private var router = NavigationRouter()
    @Environment(\.diContainer) private var container
    @FocusState private var focusedOnStatusMessageTextField: Bool

    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    HStack {
                        CacheableImage(url: viewModel.state.avatarURL)
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
                                set: { viewModel.send(.updateStatusMessage($0)) })
                            ) {
                                HStack {
                                    Text("상태 설정")
                                }
                            }
                            .focused($focusedOnStatusMessageTextField)
                            
                            if viewModel.state.resetButtonEnabled {
                                Button(action: {
                                    viewModel.send(.tapResetStatusMessageButton)
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
                                focusedOnStatusMessageTextField = false
                                viewModel.send(.willUpdateStatusMessage)
                            }) {
                                Text("완료")
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    activityHeatmapSection
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 0) {
                        Button {
                            router.push(Path.settings)
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .navigationDestination(for: Path.self) { _ in
                SettingView(viewModel: SettingViewModel(
                    deleteAuthUseCase: container.resolve(DeleteAuthUseCase.self),
                    signOutUseCase: container.resolve(SignOutUseCase.self),
                    sessionUseCase: container.resolve(AuthSessionUseCase.self),
                    observeSystemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self),
                    updateSystemThemeUseCase: container.resolve(UpdateSystemThemeUseCase.self)
                ))
                .environmentObject(router)
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .onChange(of: focusedOnStatusMessageTextField) { newValue in
                withAnimation {
                    viewModel.send(.updateStatusTextFieldFocus(newValue))
                }
            }
            .alert(
                "", isPresented: Binding(
                get: { viewModel.state.showAlert },
                set: { viewModel.send(.setAlert($0)) }
            )) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(viewModel.state.alertMessage)
            }
            .sheet(item: Binding(
                get: { viewModel.state.selectedActivityForSheet },
                set: { viewModel.send(.setSelectedActivityForSheet($0)) }
            )) { activity in
                ProfileActivityTodoSheetView(activity: activity)
            }
        }
    }

    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("분기별 활동 히트맵")
                    .font(.headline)
                Spacer()
                activityTypeSelector
            }

            quarterNavigator

            if viewModel.state.selectedQuarter == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else if let quarter = viewModel.state.selectedQuarter {
                ProfileHeatmapView(
                    quarter: quarter,
                    selectedActivityTypes: viewModel.state.selectedActivityTypes,
                    selectedDay: viewModel.state.selectedDay,
                    onSelectDay: { day in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.send(.selectDay(day))
                        }
                    }
                )
                .padding(.vertical, 6)

                if let selectedDay = viewModel.state.selectedDay {
                    selectedDayDetailSection(for: selectedDay)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                EmptyView()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private var activityTypeSelector: some View {
        Menu {
            ForEach(ProfileActivityType.allCases, id: \.self) { activityType in
                Button {
                    viewModel.send(.toggleActivityType(activityType))
                } label: {
                    HStack {
                        Text(activityType.title)
                        if viewModel.state.selectedActivityTypes.contains(activityType) {
                            Image(systemName: "checkmark")
                                .tint(.blue)
                        }
                    }
                }
            }
        } label: {
            Text("편집")
                .foregroundStyle(.blue)
        }
    }

    private var quarterNavigator: some View {
        HStack {
            Button {
                viewModel.send(.moveQuarter(-1))
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!viewModel.state.canMoveToPreviousQuarter)

            Spacer()

            Text(quarterTitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                viewModel.send(.moveQuarter(1))
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.state.canMoveToNextQuarter)
        }
    }

    private var quarterTitle: String {
        guard let start = viewModel.state.selectedQuarterStart else { return "" }
        let calendar = Calendar.current
        let year = calendar.component(.year, from: start)
        let month = calendar.component(.month, from: start)
        let quarter = ((month - 1) / 3) + 1
        return "\(year) Q\(quarter)"
    }

    @ViewBuilder
    private func selectedDayDetailSection(for day: ProfileCompletionDay) -> some View {
        let activities = viewModel.state.selectedDayActivities

        VStack(alignment: .leading, spacing: 8) {
            Text(day.date.formatted(.dateTime.month(.wide).day()))
                .font(.subheadline)
                .bold()

            if activities.isEmpty {
                Text("활동 없음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(activities) { activity in
                    Button {
                        viewModel.send(.setSelectedActivityForSheet(activity))
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: activity.todo.kind.symbolName)
                                .foregroundStyle(activity.todo.kind.color)
                                .frame(width: 20)
                            Text(activity.todo.title)
                                .font(.caption)
                                .lineLimit(1)
                            Text(activity.activityLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray4))
                                )
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.top, 4)
    }

    private enum Path: Hashable {
        case settings
    }
}

private struct ProfileActivityTodoSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let activity: ProfileSelectedDayActivity
    @State private var showInfo: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.secondarySystemBackground).ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(activity.activityLabel)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray4))
                                )
                            Spacer()
                        }
                        .padding(.horizontal)
                        Text(activity.todo.title)
                            .font(.title3.bold())
                            .padding(.horizontal)
                        Divider()
                        Markdown(activity.todo.content)
                            .padding(.horizontal)
                    }
                }
            }
            .sheet(isPresented: $showInfo) {
                infoSheetContent
            }
            .toolbar {
                ToolbarLeadingButton {
                    dismiss()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
    }

    private var infoSheetContent: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 32) {
                    VStack {
                        HStack {
                            Text("마감일")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(
                                activity.todo.dueDate?
                                    .formatted(date: .abbreviated, time: .omitted)
                                    ?? "마감일 없음"
                            )
                            .foregroundStyle(activity.todo.dueDate == nil ? .secondary : .primary)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemFill))
                        )
                        Divider()
                    }
                    VStack {
                        HStack {
                            Text("태그")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Divider()
                        if !activity.todo.tags.isEmpty {
                            TagLayout {
                                ForEach(activity.todo.tags, id: \.self) { tag in
                                    Tag(tag, isEditing: false)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarLeadingButton {
                    showInfo = false
                }
            }
        }
    }
}
