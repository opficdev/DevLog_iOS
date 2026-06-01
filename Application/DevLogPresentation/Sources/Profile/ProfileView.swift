//
//  ProfileView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import DevLogCore
import DevLogDomain

struct ProfileView: View {
    let coordinator: ProfileViewCoordinator
    let isCompactLayout: Bool
    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if isCompactLayout {
                NavigationStack(path: navigationPath) {
                    profileContentView
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    coordinator.router.push(.settings)
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                            }
                        }
                        .navigationDestination(for: ProfileRoute.self) { route in
                            profileDestinationView(route)
                        }
                }
            } else {
                profileContentView
            }
        }
        .onChange(of: focused) { _, newValue in
            withAnimation {
                coordinator.viewModel.send(.updateStatusTextFieldFocus(newValue))
            }
        }
        .alert(
            "",
            isPresented: Binding(
                get: { coordinator.viewModel.state.showAlert },
                set: { coordinator.viewModel.send(.setAlert($0)) }
            )
        ) {
            Button(String(localized: "common_close"), role: .cancel) { }
        } message: {
            Text(coordinator.viewModel.state.alertMessage)
        }
        .sheet(
            isPresented: Binding(
                get: { coordinator.viewModel.state.showQuarterPicker },
                set: { coordinator.viewModel.send(.setQuarterPickerPresented($0)) }
            )
        ) {
            quarterPickerSheet
        }
    }

    private var profileContentView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                HStack {
                    CacheableImage(url: coordinator.viewModel.state.avatarURL) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(Color(.systemGray2))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(30)
                    .foregroundStyle(Color.gray)

                    VStack(alignment: .leading) {
                        Text(coordinator.viewModel.state.name)
                            .font(.title2)
                            .bold()
                        Text(coordinator.viewModel.state.email)
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }
                let connected = coordinator.viewModel.state.isNetworkConnected
                HStack {
                    HStack {
                        Image(systemName: "face.smiling")
                        TextField(
                            text: Binding(
                                get: { coordinator.viewModel.state.statusMessage },
                                set: { coordinator.viewModel.send(.updateStatusMessage($0)) }
                            )
                        ) {
                            Text(String(localized: "profile_status_placeholder"))
                        }
                        .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight)
                        .focused($focused)
                        .disabled(!connected)

                        if !coordinator.viewModel.state.statusMessage.isEmpty,
                           coordinator.viewModel.state.showDoneButton {
                            Button(action: {
                                coordinator.viewModel.send(.tapResetStatusMessageButton)
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
                    if coordinator.viewModel.state.showDoneButton {
                        Button(action: {
                            focused = false
                            coordinator.viewModel.send(.willUpdateStatusMessage)
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
        .refreshable { coordinator.viewModel.send(.refresh) }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func profileDestinationView(_ route: ProfileRoute) -> some View {
        switch route {
        case .settings:
            SettingView(viewModel: coordinator.settingViewModel)
                .environment(coordinator.router)
        case .activity(let todoId):
            TodoDetailView(viewModel: coordinator.makeTodoDetailViewModel(todoId: todoId))
        case .theme:
            ThemeView(
                theme: Binding(
                    get: { coordinator.settingViewModel.state.theme },
                    set: { coordinator.settingViewModel.send(.setTheme($0)) }
                )
            )
        case .pushNotification:
            PushNotificationSettingsView(viewModel: coordinator.makePushNotificationSettingsViewModel())
        case .account:
            AccountView(viewModel: coordinator.makeAccountViewModel())
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

            if let quarter = coordinator.viewModel.state.activityQuarter {
                HeatmapView(
                    quarter: quarter,
                    selectedActivityKinds: coordinator.viewModel.state.selectedActivityKinds,
                    selectedDay: coordinator.viewModel.state.selectedDay,
                    onSelectDay: { coordinator.viewModel.send(.selectDay($0)) }
                )
                if let selectedDay = coordinator.viewModel.state.selectedDay {
                    selectedDayDetailSection(for: selectedDay)
                        .overlay {
                            if coordinator.viewModel.state.isLoading {
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
        if !coordinator.viewModel.isViewingCurrentQuarter {
            Button {
                coordinator.viewModel.send(.moveToCurrentQuarter)
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
                            return coordinator.viewModel.state.selectedActivityKinds.contains(activityKind)
                        },
                        set: { _ in
                            guard let activityKind = ActivityKind(rawValue: activityKindItem.rawValue) else {
                                return
                            }
                            coordinator.viewModel.send(.toggleActivityKind(activityKind))
                        }
                    )
                )
                .disabled({
                    guard let activityKind = ActivityKind(rawValue: activityKindItem.rawValue) else {
                        return false
                    }
                    return coordinator.viewModel.state.selectedActivityKinds.count == 1
                        && coordinator.viewModel.state.selectedActivityKinds.contains(activityKind)
                }())
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
                coordinator.viewModel.send(.moveQuarter(-1))
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!coordinator.viewModel.canMoveToPreviousQuarter)
            Spacer()
            Button {
                coordinator.viewModel.send(.openQuarterPicker)
            } label: {
                HStack(spacing: 4) {
                    Text(coordinator.viewModel.quarterTitle)
                        .font(.subheadline)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                coordinator.viewModel.send(.moveQuarter(1))
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!coordinator.viewModel.canMoveToNextQuarter)
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
                    Picker(
                        "",
                        selection: Binding(
                            get: { coordinator.viewModel.state.selectedQuarterPickerYear },
                            set: { coordinator.viewModel.send(.setQuarterPickerYear($0)) }
                        )
                    ) {
                        ForEach(coordinator.viewModel.availableQuarterYears, id: \.self) { year in
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
                    coordinator.viewModel.send(.setQuarterPickerPresented(false))
                }
            }
        }
        .presentationDetents([.fraction(0.3)])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func quarterSelectionButton(for quarter: Int) -> some View {
        let quarterStart = coordinator.viewModel.quarterStartForPicker(quarter: quarter)
        let isEnabled = coordinator.viewModel.isQuarterSelectableForPicker(quarter)
        let isSelected = coordinator.viewModel.isQuarterSelectedForPicker(quarter)

        Button {
            guard let quarterStart else { return }
            coordinator.viewModel.send(.selectQuarter(quarterStart))
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
    private func selectedDayDetailSection(for day: HeatmapDay) -> some View {
        let activities = coordinator.viewModel.selectedDayActivities

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
                            coordinator.router.push(.activity(activity.todoId))
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

    private var navigationPath: Binding<[ProfileRoute]> {
        Binding(
            get: { coordinator.router.path },
            set: { coordinator.router.path = $0 }
        )
    }
}

enum ProfileRoute: Hashable {
    case settings
    case activity(String)
    case theme
    case pushNotification
    case account
}
