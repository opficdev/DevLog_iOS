//
//  TodayView.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import SwiftUI

struct TodayView: View {
    @Environment(\.diContainer) private var container: any DIContainer
    @State private var router = NavigationRouter()
    @State var viewModel: TodayViewModel

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                summarySection
                if viewModel.sections.isEmpty, !viewModel.state.isLoading {
                    emptySection
                } else {
                    ForEach(viewModel.sections) { section in
                        todoSection(section.title, items: section.items)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("오늘")
            .toolbar { toolbarContent }
            .navigationDestination(for: Path.self) { path in
                switch path {
                case .detail(let todoID):
                    TodoDetailView(viewModel: TodoDetailViewModel(
                        fetchUseCase: container.resolve(FetchTodoByIDUseCase.self),
                        upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                        todoID: todoID
                    ))
                }
            }
            .background(NavigationBarConfigurator())
            .refreshable { viewModel.send(.refresh) }
            .onAppear { viewModel.send(.onAppear) }
            .alert(
                viewModel.state.alertTitle,
                isPresented: Binding(
                    get: { viewModel.state.showAlert },
                    set: { viewModel.send(.setAlert($0)) }
                )
            ) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(viewModel.state.alertMessage)
            }
            .overlay {
                if viewModel.state.isLoading {
                    LoadingView()
                }
            }
        }
    }

    private var summarySection: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(TodayViewModel.SummaryScope.allCases, id: \.self) { scope in
                        Button {
                            withAnimation(.easeInOut) {
                                viewModel.send(.setSummaryScope(scope))
                            }
                        } label: {
                            SummaryCard(
                                title: scope.title,
                                value: viewModel.summaryValue(for: scope),
                                accentColor: scope.accentColor,
                                isSelected: viewModel.state.selectedSummaryScope == scope
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.never)
            .contentMargins(.horizontal, 16)
        }
        .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker(
                    "보기 범위",
                    selection: Binding(
                        get: { viewModel.state.displayOptions.dueDateVisibility },
                        set: { viewModel.send(.setDueDateVisibility($0)) }
                    )
                ) {
                    ForEach(TodayDisplayOptions.DueDateVisibility.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }

                Toggle(
                    "중요 표시만",
                    isOn: Binding(
                        get: { viewModel.state.displayOptions.focusVisibility == .focusedOnly },
                        set: {
                            viewModel.send(.setFocusVisibility($0 ? .focusedOnly : .all))
                        }
                    )
                )
                .tint(.orange)

                if viewModel.state.displayOptions.focusVisibility == .focusedOnly {
                    Text("중요 표시한 Todo만 표시됩니다.")
                        .font(.caption)
                }
            } label: {
                let options = viewModel.state.displayOptions
                Image(systemName: "line.3.horizontal.decrease.circle\(options == .default ? "" : ".fill")")
            }
        }
    }

    private var emptySection: some View {
        Section {
            VStack(spacing: 8) {
                Text(emptyStateContent.title)
                    .foregroundStyle(.primary)
                Text(emptyStateContent.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
    }

    @ViewBuilder
    private func todoSection(_ title: String, items: [TodayTodoItem]) -> some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    NavigationLink(value: Path.detail(item.id)) {
                        TodayTodoRow(item: item)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            viewModel.send(.togglePinned(item))
                        } label: {
                            Image(systemName: item.isPinned ? "star.slash" : "star.fill")
                        }
                        .tint(.orange)

                        Button {
                            viewModel.send(.completeTodo(item))
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .tint(.green)
                    }
                }
            } header: {
                Text(title)
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    private var emptyStateContent: EmptyStateContent {
        switch viewModel.state.selectedSummaryScope {
        case .all:
            if viewModel.state.todos.isEmpty {
                return EmptyStateContent(
                    title: "남아 있는 Todo가 없습니다.",
                    message: "완료되지 않은 일이 생기면 이곳에서 우선순위대로 볼 수 있습니다."
                )
            }
            return EmptyStateContent(
                title: "선택한 보기 옵션에 맞는 Todo가 없습니다.",
                message: "툴바에서 보기 범위를 조정하거나 전체 보기로 돌아가세요."
            )
        case .focused:
            return EmptyStateContent(
                title: "집중할 일이 없습니다.",
                message: "중요 표시한 Todo가 생기면 이곳에서 바로 볼 수 있습니다."
            )
        case .overdue:
            return EmptyStateContent(
                title: "지난 마감 Todo가 없습니다.",
                message: "지금은 기한이 지난 Todo가 없습니다."
            )
        case .dueSoon:
            return EmptyStateContent(
                title: "7일 내 일정이 없습니다.",
                message: "곧 마감되는 Todo가 생기면 이곳에서 먼저 볼 수 있습니다."
            )
        }
    }

    private struct EmptyStateContent {
        let title: String
        let message: String
    }

    private enum Path: Hashable {
        case detail(String)
    }
}

private extension TodayDisplayOptions.DueDateVisibility {
    var title: String {
        switch self {
        case .all:
            return "전체"
        case .withDueDateOnly:
            return "기한 있는 Todo만"
        case .withoutDueDateOnly:
            return "기한 없는 Todo만"
        }
    }
}

private extension TodayViewModel.SummaryScope {
    var title: String {
        switch self {
        case .all:
            return "남은 일"
        case .focused:
            return "집중"
        case .overdue:
            return "지연"
        case .dueSoon:
            return "7일 내"
        }
    }

    var accentColor: Color {
        switch self {
        case .all:
            return .blue
        case .focused:
            return .orange
        case .overdue:
            return .red
        case .dueSoon:
            return .green
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: Int
    let accentColor: Color
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(isSelected ? accentColor : .secondary)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(Color(.label))
        }
        .frame(width: 96, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? accentColor.opacity(0.2) : accentColor.opacity(0.12))
                .strokeBorder(
                    isSelected ? accentColor.opacity(0.55) : accentColor.opacity(0.18),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .scaleEffect(isSelected ? 1 : 0.98)
    }
}

private struct TodayTodoRow: View {
    private let calendar = Calendar.current
    let item: TodayTodoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: item.kind.symbolName)
                    .foregroundStyle(item.kind.color)
                    .frame(width: 18)
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
                Spacer()
            }

            HStack(spacing: 8) {
                Text(item.kind.localizedName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.kind.color)

                if let dueDate {
                    Text(dueDate.text)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dueDate.textColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(dueDate.backgroundColor)
                        )
                }
            }

            if !item.tags.isEmpty {
                TagList(item.tags, lineLimit: 1)
            }
        }
    }

    private var dueDate: DueDateBadge? {
        guard let date = item.dueDate else { return nil }
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: date)

        if dueDay < today {
            return DueDateBadge(
                text: "기한 지남",
                textColor: .red,
                backgroundColor: Color.red.opacity(0.12)
            )
        }

        let formatted = date.formatted(date: .abbreviated, time: .omitted)
        return DueDateBadge(
            text: formatted,
            textColor: .blue,
            backgroundColor: Color.blue.opacity(0.12)
        )
    }

    private struct DueDateBadge {
        let text: String
        let textColor: Color
        let backgroundColor: Color
    }
}
