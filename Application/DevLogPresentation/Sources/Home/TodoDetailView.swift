//
//  TodoDetailView.swift
//  DevLogPresentation
//
//  Created by opfic on 6/12/25.
//

import SwiftUI
import DevLogCore
import DevLogDomain

struct TodoDetailView: View {
    @Environment(\.diContainer) private var container: DIContainer
    @Environment(TodoEditorWindowEvent.self) private var windowEvent
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @State var viewModel: TodoDetailViewModel

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()
            if let todo = viewModel.state.todo, let number = todo.number {
                TodoDetailContentView(
                    title: todo.title,
                    content: todo.content,
                    referenceItems: viewModel.state.referenceItems,
                    number: number,
                    onOpenTodoID: { viewModel.send(.setSelectedTodoId(TodoIdItem(id: $0))) }
                )
            } else if viewModel.state.isLoading {
                LoadingView()
            }
        }
        .onAppear { viewModel.send(.onAppear) }
        .onChange(of: windowEvent.submitted) { _, submitted in
            handleTodoEditorSubmit(submitted)
        }
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
                        fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                        upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                        onUpsertSuccess: { todo in
                            viewModel.send(.setShowEditor(false))
                            viewModel.send(.setTodo(todo))
                        }
                    )
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
                    openTodoEditor()
                } label: {
                    Text(String(localized: "todo_edit"))
                }
            }
        }
    }

    private func openTodoEditor() {
        if isiOSAppOnMac {
            guard let todo = viewModel.state.todo else { return }
            openWindow(
                id: TodoEditorWindowValue.sceneId,
                value: TodoEditorWindowValue(todo: todo)
            )
        } else {
            viewModel.send(.setShowEditor(true))
        }
    }

    private func handleTodoEditorSubmit(_ submit: TodoEditorWindowSubmit?) {
        guard let submit,
              submit.value.matchesEdit(todoId: viewModel.todoId) else { return }
        viewModel.send(.setTodo(submit.todo))
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
                Section(String(localized: "todo_options_section")) {
                    HStack {
                        Text(String(localized: "todo_category"))
                        Spacer()
                        Text(TodoCategoryItem(from: todo.category).localizedName)
                            .foregroundStyle(.secondary)
                    }

                    statusRow(
                        title: String(localized: "todo_completed"),
                        systemImage: todo.isCompleted ? "checkmark.circle.fill" : "circle",
                        color: todo.isCompleted ? .green : .secondary
                    )

                    statusRow(
                        title: String(localized: "todo_pinned"),
                        systemImage: todo.isPinned ? "star.fill" : "star",
                        color: todo.isPinned ? .orange : .secondary
                    )

                    HStack {
                        Text(String(localized: "todo_due_date"))

                        Spacer()

                        if let dueDate = todo.dueDate {
                            Tag(dueDateText(for: dueDate), isEditing: false)
                                .padding(.vertical, -4)
                        } else {
                            Text(String(localized: "todo_none"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(String(localized: "todo_tags")) {
                    if todo.tags.isEmpty {
                        Text(String(localized: "todo_no_tags"))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        TagList(todo.tags)
                    }
                }
            }
            .navigationTitle(String(localized: "todo_details"))
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
