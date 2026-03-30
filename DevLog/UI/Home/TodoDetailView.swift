//
//  TodoDetailView.swift
//  DevLog
//
//  Created by opfic on 6/12/25.
//

import SwiftUI

struct TodoDetailView: View {
    @Environment(\.diContainer) private var container: DIContainer
    @State var viewModel: TodoDetailViewModel

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()
            if let todo = viewModel.state.todo {
                TodoDetailContentView(
                    title: todo.title,
                    content: todo.content,
                    referenceItems: viewModel.state.referenceItems,
                    number: todo.number,
                    onOpenTodoID: { viewModel.send(.setSelectedTodoId(TodoIdItem(id: $0))) }
                )
            } else if viewModel.state.isLoading {
                LoadingView()
            }
        }
        .onAppear { viewModel.send(.onAppear) }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { viewModel.state.showInfo },
            set: { viewModel.send(.setShowInfo($0)) }
        )) {
            sheetContent
        }
        .sheet(item: Binding(
            get: { viewModel.state.selectedTodoId },
            set: { viewModel.send(.setSelectedTodoId($0)) }
        )) { item in
            NavigationStack {
                TodoDetailView(viewModel: TodoDetailViewModel(
                    fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
                    fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                    upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                    todoId: item.id,
                    showEditButton: false
                ))
                .toolbar {
                    ToolbarLeadingButton {
                        viewModel.send(.setSelectedTodoId(nil))
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.state.showEditor },
            set: { viewModel.send(.setShowEditor($0)) }
        )) {
            if let todo = viewModel.state.todo {
                TodoEditorView(
                    viewModel: TodoEditorViewModel(
                        todo: todo,
                        fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
                        fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self)
                    ),
                    onSubmit: { viewModel.send(.upsertTodo($0)) }
                )
            }
        }
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.send(.setShowInfo(true))
            } label: {
                Image(systemName: "info.circle")
            }
        }
        if viewModel.showEditButton {
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.send(.setShowEditor(true))
                } label: {
                    Text("수정")
                }
            }
        }
    }

    @ViewBuilder
    private var sheetContent: some View {
        if let todo = viewModel.state.todo {
            TodoDetailInfoSheetView(todo: todo) {
                viewModel.send(.setShowInfo(false))
            }
        }
    }
}

private struct TodoDetailInfoSheetView: View {
    let todo: Todo
    let onClose: () -> Void
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                Section("옵션") {
                    HStack {
                        Text("카테고리")
                        Spacer()
                        Text(todo.category.localizedName)
                            .foregroundStyle(.secondary)
                    }

                    statusRow(
                        title: "완료",
                        systemImage: todo.isCompleted ? "checkmark.circle.fill" : "circle",
                        color: todo.isCompleted ? .green : .secondary
                    )

                    statusRow(
                        title: "중요 표시",
                        systemImage: todo.isPinned ? "star.fill" : "star",
                        color: todo.isPinned ? .orange : .secondary
                    )

                    HStack {
                        Text("마감일")

                        Spacer()

                        if let dueDate = todo.dueDate {
                            Tag(dueDateText(for: dueDate), isEditing: false)
                                .padding(.vertical, -4)
                        } else {
                            Text("없음")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("태그") {
                    if todo.tags.isEmpty {
                        Text("태그 없음")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        TagList(todo.tags)
                    }
                }
            }
            .navigationTitle("세부 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarLeadingButton {
                    onClose()
                }
            }
        }
    }

    @ViewBuilder
    private func statusRow(
        title: String,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            Image(systemName: systemImage)
                .foregroundStyle(color)
        }
    }

    private func dueDateText(for dueDate: Date) -> String {
        let currentYear = calendar.component(.year, from: Date())
        let dueDateYear = calendar.component(.year, from: dueDate)

        if currentYear == dueDateYear {
            return dueDate.formatted(
                .dateTime.month(.defaultDigits).day(.defaultDigits)
            )
        }

        return dueDate.formatted(
            .dateTime.year(.twoDigits).month(.defaultDigits).day(.defaultDigits)
        )
    }
}
