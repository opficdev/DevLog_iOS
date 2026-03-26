//
//  ProfileView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

struct ProfileView: View {
    @State var viewModel: ProfileViewModel
    @State private var router = NavigationRouter()
    @Environment(\.diContainer) private var container
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    HStack {
                        CacheableImage(url: viewModel.state.avatarURL) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundStyle(Color(.systemGray2))
                        }
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
                            .focused($focused)

                            if !viewModel.state.statusMessage.isEmpty && viewModel.state.showDoneButton {
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
                                focused = false
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
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 0) {
                        Button {
                            router.push(Path.settings)
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .navigationDestination(for: Path.self) { path in
                switch path {
                case .settings:
                    SettingView(viewModel: SettingViewModel(
                        deleteAuthUseCase: container.resolve(DeleteAuthUseCase.self),
                        signOutUseCase: container.resolve(SignOutUseCase.self),
                        systemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self),
                        updateSystemThemeUseCase: container.resolve(UpdateSystemThemeUseCase.self)
                    ))
                    .environment(router)
                case .activity(let activity):
                    ProfileActivityTodoDetailView(activity: activity)
                }
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .onChange(of: focused) { _, newValue in
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
            .sheet(isPresented: Binding(
                get: { viewModel.state.showQuarterPicker },
                set: { viewModel.send(.setQuarterPickerPresented($0)) }
            )) {
                quarterPickerSheet
            }
        }
    }

    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("분기별 활동")
                    .font(.headline)
                Spacer()
                quarterResetButton
                activityTypeSelector
            }

            quarterNavigator

            if let quarter = viewModel.state.completionQuarter {
                ProfileTrendChartView(
                    trendPoints: viewModel.state.completionQuarter?.weeklyTrendPoints ?? [],
                    selectedActivityTypes: viewModel.state.selectedActivityTypes
                )
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
                if let selectedDay = viewModel.state.selectedDay {
                    selectedDayDetailSection(for: selectedDay)
                        .transition(.opacity)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 140)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    private var quarterResetButton: some View {
        if !viewModel.isViewingCurrentQuarter {
            Button {
                viewModel.send(.moveToCurrentQuarter)
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .bold()
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
    }

    private var activityTypeSelector: some View {
        Menu {
            ForEach(ProfileActivityType.allCases, id: \.self) { activityType in
                Toggle(
                    activityType.title,
                    isOn: Binding(
                        get: { viewModel.state.selectedActivityTypes.contains(activityType) },
                        set: { _ in
                            viewModel.send(.toggleActivityType(activityType))
                        }
                    )
                )
                .disabled(
                    viewModel.state.selectedActivityTypes.count == 1
                        && viewModel.state.selectedActivityTypes.contains(activityType)
                )
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .bold()
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
            .disabled(!viewModel.canMoveToPreviousQuarter)
            Spacer()
            Button {
                viewModel.send(.openQuarterPicker)
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.quarterTitle)
                        .font(.subheadline)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                viewModel.send(.moveQuarter(1))
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.canMoveToNextQuarter)
        }
    }

    private var quarterPickerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("연도")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { viewModel.state.selectedQuarterPickerYear },
                        set: { viewModel.send(.setQuarterPickerYear($0)) }
                    )) {
                        ForEach(viewModel.availableQuarterYears, id: \.self) { year in
                            Text(year.formatted(.number.grouping(.never)) + "년").tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(1...4, id: \.self) { quarter in
                        quarterSelectionButton(for: quarter)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("분기 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarTrailingButton {
                    viewModel.send(.setQuarterPickerPresented(false))
                }
            }
        }
        .presentationDetents([.fraction(0.3)])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func quarterSelectionButton(for quarter: Int) -> some View {
        let quarterStart = viewModel.quarterStartForPicker(quarter: quarter)
        let isEnabled = viewModel.isQuarterSelectableForPicker(quarter)
        let isSelected = viewModel.isQuarterSelectedForPicker(quarter)

        Button {
            guard let quarterStart else { return }
            viewModel.send(.selectQuarter(quarterStart))
        } label: {
            Text("Q\(quarter)")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .foregroundStyle(isSelected ? .white : isEnabled ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    @ViewBuilder
    private func selectedDayDetailSection(for day: ProfileCompletionDay) -> some View {
        let activities = viewModel.selectedDayActivities

        VStack(alignment: .leading, spacing: 12) {
            Text(day.date.formatted(.dateTime.year().month(.wide).day()))
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
                        router.push(Path.activity(activity))
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
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(.rect)
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
        case activity(ProfileSelectedDayActivity)
    }
}

private struct ProfileActivityTodoDetailView: View {
    let activity: ProfileSelectedDayActivity
    @State private var showInfo: Bool = false

    var body: some View {
        TodoDetailContentView(
            title: activity.todo.title,
            content: activity.todo.content,
            referenceItems: [:],
            number: activity.todo.number,
            activityLabel: activity.activityLabel
        )
        .sheet(isPresented: $showInfo) {
            infoSheetContent
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
    }

    private var infoSheetContent: some View {
        TodoInfoSheetView(
            createdAt: activity.todo.createdAt,
            completedAt: activity.todo.completedAt,
            dueDate: activity.todo.dueDate,
            tags: activity.todo.tags
        ) {
            showInfo = false
        }
    }
}
