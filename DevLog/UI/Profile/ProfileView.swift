//
//  ProfileView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

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
        }
    }

    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("분기별 활동 히트맵")
                    .font(.headline)
                Spacer()
                metricSelector
            }

            quarterNavigator

            if viewModel.state.completionQuarters.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else if let quarter = viewModel.state.selectedQuarter {
                QuarterHeatmapView(
                    quarter: quarter,
                    selectedMetrics: viewModel.state.selectedMetrics
                )
                .padding(.vertical, 6)
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

    private var metricSelector: some View {
        Menu {
            ForEach(ProfileViewModel.HeatmapMetric.allCases, id: \.self) { metric in
                Button {
                    viewModel.send(.toggleHeatmapMetric(metric))
                } label: {
                    HStack {
                        Text(metric.title)
                        if viewModel.state.selectedMetrics.contains(metric) {
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
        guard let start = viewModel.state.selectedQuarter?.quarterStart else { return "" }
        let calendar = Calendar.current
        let year = calendar.component(.year, from: start)
        let month = calendar.component(.month, from: start)
        let quarter = ((month - 1) / 3) + 1
        return "\(year) Q\(quarter)"
    }

    private enum Path: Hashable {
        case settings
    }
}

private struct QuarterHeatmapView: View {
    let quarter: ProfileViewModel.CompletionQuarter
    let selectedMetrics: Set<ProfileViewModel.HeatmapMetric>

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            weekdayLabel
                .padding(.trailing, 10)
            let months = quarter.months
            ForEach(Array(zip(months.indices, months)), id: \.1) { index, month in
                MonthCompactHeatmapView(
                    month: month,
                    selectedMetrics: selectedMetrics
                )
                if index < months.count - 1 {
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var weekdayLabel: some View {
        let labels: [Int: String] = [
            2: "월",
            4: "수",
            6: "금"
        ]
        let orderedWeekdays = Array(1...7)
        let cellSize: CGFloat = 16

        VStack(alignment: .leading, spacing: 4) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                Group {
                    if let label = labels[weekday] {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: cellSize, height: cellSize)
                    } else {
                        Color.clear
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .padding(.top, 22)
    }
}

private struct MonthCompactHeatmapView: View {
    let month: ProfileViewModel.CompletionMonth
    let selectedMetrics: Set<ProfileViewModel.HeatmapMetric>
    private let orderedWeekdays = Array(1...7)
    private let cellSize: CGFloat = 16
    private let cellSpacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(month.monthStart.formatted(.dateTime.month(.abbreviated)))
                .frame(height: cellSize)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: cellSpacing) {
                ForEach(orderedWeekdays, id: \.self) { weekday in
                    HStack(spacing: cellSpacing) {
                        ForEach(month.weeks.indices, id: \.self) { weekIndex in
                            let day = month.weeks[weekIndex].first {
                                Calendar.current.component(.weekday, from: $0.date) == weekday
                            }

                            RoundedRectangle(cornerRadius: 3)
                                .fill(fillColor(for: day))
                                .frame(width: cellSize, height: cellSize)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(
                                            Color.secondary.opacity((day?.isInMonth ?? false) ? 0.2 : 0),
                                            lineWidth: 0.5
                                        )
                                )
                        }
                    }
                }
            }
        }
    }

    private func fillColor(for day: ProfileViewModel.CompletionDay?) -> Color {
        guard let day, day.isInMonth else { return .clear }
        return Color.blue.opacity(opacity(for: dayCount(for: day), max: monthMaxCount))
    }

    private var monthMaxCount: Int {
        month.weeks
            .flatMap { $0 }
            .filter { $0.isInMonth }
            .map(dayCount(for:))
            .max() ?? 0
    }

    private func dayCount(for day: ProfileViewModel.CompletionDay) -> Int {
        var value = 0
        if selectedMetrics.contains(.created) {
            value += day.createdCount
        }
        if selectedMetrics.contains(.completed) {
            value += day.completedCount
        }
        return value
    }

    private func opacity(for count: Int, max: Int) -> Double {
        guard 0 < count && 0 < max else { return 0 }
        let ratio = Double(count) / Double(max)
        return floor(ratio * 10) / 10
    }
}
