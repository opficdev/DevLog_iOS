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
        let sections = viewModel.sections

        NavigationStack(path: $router.path) {
            List {
                summarySection
                if sections.isEmpty, !viewModel.state.isLoading {
                    emptySection
                } else {
                    ForEach(Array(sections.indices), id: \.self) { index in
                        let section = sections[index]
                        todoSection(section.title, items: section.items)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("오늘")
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
                    SummaryCard(
                        title: "남은 일",
                        value: viewModel.remainingCount,
                        accentColor: .blue
                    )
                    SummaryCard(
                        title: "집중",
                        value: viewModel.focusedCount,
                        accentColor: .orange
                    )
                    SummaryCard(
                        title: "지연",
                        value: viewModel.overdueCount,
                        accentColor: .red
                    )
                    SummaryCard(
                        title: "7일 내",
                        value: viewModel.dueSoonCount,
                        accentColor: .green
                    )
                }
            }
            .scrollIndicators(.never)
            .contentMargins(.horizontal, 16)
        }
        .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
    }

    private var emptySection: some View {
        Section {
            VStack(spacing: 8) {
                Text("남아 있는 Todo가 없습니다.")
                    .foregroundStyle(.primary)
                Text("완료되지 않은 일이 생기면 이곳에서 우선순위대로 볼 수 있습니다.")
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

    private enum Path: Hashable {
        case detail(String)
    }
}

private struct SummaryCard: View {
    let title: String
    let value: Int
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(Color(.label))
        }
        .frame(width: 96, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accentColor.opacity(0.12))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        }
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
                TagLayout(lineLimit: 1) {
                    ForEach(item.tags, id: \.self) { tagText in
                        Tag(tagText, isEditing: false)
                    }
                }
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
