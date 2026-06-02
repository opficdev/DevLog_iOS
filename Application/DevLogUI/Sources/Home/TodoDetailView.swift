//
//  TodoDetailView.swift
//  DevLogUI
//
//  Created by opfic on 6/12/25.
//

import SwiftUI
import DevLogPresentation

public struct TodoDetailView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @State var viewModel: TodoDetailViewModel
    let todoViewModelFactory: TodoViewModelFactory

    public init(
        viewModel: TodoDetailViewModel,
        todoViewModelFactory: TodoViewModelFactory
    ) {
        self.viewModel = viewModel
        self.todoViewModelFactory = todoViewModelFactory
    }

    public var body: some View {
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
                TodoDetailView(
                    viewModel: todoViewModelFactory.makeDetailViewModel(
                        todoId: item.id,
                        showEditButton: false
                    ),
                    todoViewModelFactory: todoViewModelFactory
                )
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
                    viewModel: todoViewModelFactory.makeEditorViewModel(
                        todo: todo,
                        onUpsertSuccess: { todo in
                            viewModel.send(.setShowEditor(false))
                            viewModel.send(.setTodo(todo))
                        }
                    ),
                    todoViewModelFactory: todoViewModelFactory
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

    @ViewBuilder
    private var sheetContent: some View {
        if let todo = viewModel.state.todo {
            TodoDetailInfoSheetView(
                categoryName: TodoCategoryItem(from: todo.category).localizedName,
                isCompleted: todo.isCompleted,
                isPinned: todo.isPinned,
                dueDate: todo.dueDate,
                tags: todo.tags
            ) {
                viewModel.send(.setShowInfo(false))
            }
        }
    }
}

private struct TodoDetailInfoSheetView: View {
    let categoryName: String
    let isCompleted: Bool
    let isPinned: Bool
    let dueDate: Date?
    let tags: [String]
    let onClose: () -> Void
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "todo_options_section")) {
                    HStack {
                        Text(String(localized: "todo_category"))
                        Spacer()
                        Text(categoryName)
                            .foregroundStyle(.secondary)
                    }

                    statusRow(
                        title: String(localized: "todo_completed"),
                        systemImage: isCompleted ? "checkmark.circle.fill" : "circle",
                        color: isCompleted ? .green : .secondary
                    )

                    statusRow(
                        title: String(localized: "todo_pinned"),
                        systemImage: isPinned ? "star.fill" : "star",
                        color: isPinned ? .orange : .secondary
                    )

                    HStack {
                        Text(String(localized: "todo_due_date"))

                        Spacer()

                        if let dueDate {
                            Tag(dueDateText(for: dueDate), isEditing: false)
                                .padding(.vertical, -4)
                        } else {
                            Text(String(localized: "todo_none"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(String(localized: "todo_tags")) {
                    if tags.isEmpty {
                        Text(String(localized: "todo_no_tags"))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        TagList(tags)
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
