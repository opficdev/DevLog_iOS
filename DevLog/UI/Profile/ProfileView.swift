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
                    let connected = viewModel.state.isNetworkConnected
                    HStack {
                        HStack {
                            Image(systemName: "face.smiling")
                            TextField(text: Binding(
                                get: { viewModel.state.statusMessage },
                                set: { viewModel.send(.updateStatusMessage($0)) })
                            ) {
                                Text(String(localized: "profile_status_placeholder"))
                            }
                            .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight)
                            .focused($focused)
                            .disabled(!connected)

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
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        if viewModel.state.showDoneButton {
                            Button(action: {
                                focused = false
                                viewModel.send(.willUpdateStatusMessage)
                            }) {
                                Text(String(localized: "profile_done"))
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .opacity(connected ? 1 : 0.7)
                    activityHeatmapSection
                }
                .padding(.horizontal, 16)
            }
            .refreshable { viewModel.send(.refresh) }
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
                        networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
                        systemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self),
                        updateSystemThemeUseCase: container.resolve(UpdateSystemThemeUseCase.self),
                        fetchWebPageImageDirSizeUseCase: container.resolve(FetchWebPageImageDirSizeUseCase.self),
                        clearWebPageImageDirectoryUseCase: container.resolve(ClearWebPageImageDirectoryUseCase.self)
                    ))
                    .environment(router)
                case .activity(let todoId):
                    TodoDetailView(viewModel: TodoDetailViewModel(
                        fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
                        fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                        upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                        todoId: todoId,
                        showEditButton: false
                    ))
                }
            }
            .onAppear { viewModel.send(.onAppear) }
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
                Button(String(localized: "common_close"), role: .cancel) { }
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
                Text(String(localized: "profile_quarterly_activity"))
                    .font(.headline)
                Spacer()
                quarterResetButton
                activityTypeSelector
            }

            quarterNavigator

            if let quarter = viewModel.state.activityQuarter {
                ProfileHeatmapView(
                    quarter: quarter,
                    selectedActivityKinds: viewModel.state.selectedActivityKinds,
                    selectedDay: viewModel.state.selectedDay,
                    onSelectDay: { viewModel.send(.selectDay($0)) }
                )
                if let selectedDay = viewModel.state.selectedDay {
                    selectedDayDetailSection(for: selectedDay)
                        .overlay {
                            if viewModel.state.isLoading {
                                LoadingView()
                            }
                        }
                }
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
            ForEach(ActivityKindItem.selectableItems) { activityKindItem in
                Toggle(
                    activityKindItem.title,
                    isOn: Binding(
                        get: {
                            guard let activityKind = ActivityKind(rawValue: activityKindItem.rawValue) else {
                                return false
                            }
                            return viewModel.state.selectedActivityKinds.contains(activityKind)
                        },
                        set: { _ in
                            guard let activityKind = ActivityKind(rawValue: activityKindItem.rawValue) else {
                                return
                            }
                            viewModel.send(.toggleActivityKind(activityKind))
                        }
                    )
                )
                .disabled(
                    {
                        guard let activityKind = ActivityKind(rawValue: activityKindItem.rawValue) else {
                            return false
                        }
                        return viewModel.state.selectedActivityKinds.count == 1
                            && viewModel.state.selectedActivityKinds.contains(activityKind)
                    }()
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
                    Text(String(localized: "profile_year"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { viewModel.state.selectedQuarterPickerYear },
                        set: { viewModel.send(.setQuarterPickerYear($0)) }
                    )) {
                        ForEach(viewModel.availableQuarterYears, id: \.self) { year in
                            Text(verbatim: String(year))
                                .tag(year)
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
            .navigationTitle(String(localized: "profile_select_quarter"))
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
            Text(
                String.localizedStringWithFormat(
                    String(localized: "profile_quarter_format"),
                    Int64(quarter)
                )
            )
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
    private func selectedDayDetailSection(for day: ProfileActivityDay) -> some View {
        let activities = viewModel.selectedDayActivities

        VStack(alignment: .leading, spacing: 12) {
            Text(day.date.formatted(.dateTime.year().month(.wide).day()))
                .font(.subheadline)
                .bold()

            if activities.isEmpty {
                Text(String(localized: "profile_activity_none"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(activities) { activity in
                    Button {
                        if !activity.isDeleted {
                            router.push(Path.activity(activity.todoId))
                        }
                    } label: {
                        let item = TodoCategoryItem(from: activity.category)
                        let rowColor = activity.isDeleted ? Color.secondary : .primary
                        HStack(spacing: 8) {
                            Image(systemName: item.symbolName)
                                .foregroundStyle(item.color)
                                .frame(width: 20)
                            Text(activity.title)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(rowColor)
                            Text("#\(activity.number)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(activity.activityKindItems) { activityKindItem in
                                Text(activityKindItem.title)
                                    .font(.caption2)
                                    .foregroundStyle(activityKindItem.badgeColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(activityKindItem.badgeColor.opacity(0.14))
                                    )
                            }
                            Spacer()
                            if !activity.isDeleted {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(activity.isDeleted)
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.top, 4)
    }

    private enum Path: Hashable {
        case settings
        case activity(String)
    }
}
