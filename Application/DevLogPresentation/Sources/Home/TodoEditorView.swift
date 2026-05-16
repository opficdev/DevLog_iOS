//
//  TodoEditorView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/31/25.
//

import MarkdownUI
import OrderedCollections
import SwiftUI
import DevLogCore
import DevLogDomain

struct TodoEditorView: View {
    @State var viewModel: TodoEditorViewModel
    @Environment(\.diContainer) private var container: DIContainer
    @Environment(\.dismiss) private var dismiss
    @FocusState private var field: Field?
    private let calendar = Calendar.current
    var onSubmit: ((Todo) -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    titleField
                    LazyVStack(
                        alignment: .leading,
                        spacing: 0,
                        pinnedViews: [.sectionHeaders]
                    ) {
                        Section {
                            tabView
                        } header: {
                            tabViewSelector
                        }
                    }
                }
            }
            .onTapGesture {
                field = .content
            }
            .onAppear { viewModel.send(.onAppear) }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.background, for: .navigationBar)
            .sheet(isPresented: Binding(
                get: { viewModel.state.showInfo },
                set: { viewModel.send(.setShowInfo($0)) }
            )) {
                TodoEditorInfoSheetView(viewModel: viewModel) {
                    viewModel.send(.setShowInfo(false))
                }
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
            .toolbar {
                ToolbarLeadingButton { dismiss() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.send(.setShowInfo(true))
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
                ToolbarTrailingButton {
                    submit()
                }
                .disabled(!viewModel.isReadyToSubmit)
            }
        }
    }

    private var titleField: some View {
        TextField(
            "",
            text: Binding(
                get: { viewModel.state.title },
                set: { viewModel.send(.setTitle($0)) }
            ),
            prompt: Text(String(localized: "todo_editor_title_required")).foregroundColor(Color.secondary),
        )
        .font(.title2)
        .frame(height: 30)
        .focused($field, equals: .title)
        .padding(.horizontal)
    }

    private var tabViewSelector: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: {
                    viewModel.send(.setTabViewTag(.editor))
                    field = .content
                }) {
                    Text(String(localized: "todo_edit"))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            viewModel.state.tabViewTag == .editor ? Color.primary : Color.secondary
                        )
                }
                Divider()
                Button(action: {
                    transitionToPreview()
                }) {
                    Text(String(localized: "todo_preview"))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            viewModel.state.tabViewTag == .preview ? Color.primary : Color.gray
                        )
                }
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }

    private var tabView: some View {
        Group {
            if viewModel.state.tabViewTag == .editor {
                VStack(alignment: .leading, spacing: 8) {
                    markdownHint
                    UIKitTextEditor(
                        text: Binding(
                            get: { viewModel.state.content },
                            set: { viewModel.send(.setContent($0)) }
                        ),
                        placeholder: String(localized: "todo_editor_description_optional")
                    )
                    .focused($field, equals: .content)
                }
            } else {
                if viewModel.state.content.isEmpty {
                    previewPlaceholder
                } else {
                    TodoMarkdownContentView(
                        content: viewModel.state.content,
                        referenceItems: viewModel.state.referenceItems,
                        onOpenTodoID: { viewModel.send(.setSelectedTodoId(TodoIdItem(id: $0))) }
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var markdownHint: some View {
        Text(String(localized: "todo_editor_markdown_hint"))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var previewPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "todo_editor_markdown_preview_title"))
                .font(.subheadline.weight(.semibold))
            Text(String(localized: "todo_editor_markdown_preview_message"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func submit() {
        let todo = viewModel.makeTodo()
        onSubmit?(todo)
        dismiss()
    }

    private func transitionToPreview() {
        field = nil

        DispatchQueue.main.async {
            viewModel.send(.setTabViewTag(.preview))
        }
    }

    private enum Field: Hashable {
        case title, content
    }
}

private struct TodoEditorInfoSheetView: View {
    @Bindable var viewModel: TodoEditorViewModel
    let onClose: () -> Void
    @FocusState private var isTagFieldFocused: Bool
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "todo_options_section")) {
                    Picker(
                        String(localized: "todo_category"),
                        selection: Binding(
                            get: { viewModel.state.category.id },
                            set: { categoryId in
                                guard let item = viewModel.state.categories.first(where: {
                                    $0.id == categoryId
                                }) else {
                                    return
                                }

                                viewModel.send(.setCategory(item))
                            }
                        )
                    ) {
                        ForEach(viewModel.state.categories, id: \.id) { item in
                            Text(item.localizedName)
                                .tag(item.id)
                        }
                    }

                    Toggle(
                        String(localized: "todo_completed"),
                        isOn: Binding(
                            get: { viewModel.state.isCompleted },
                            set: { viewModel.send(.setCompleted($0)) }
                        )
                    )
                    .tint(.blue)

                    Toggle(
                        String(localized: "todo_pinned"),
                        isOn: Binding(
                            get: { viewModel.state.isPinned },
                            set: { viewModel.send(.setPinned($0)) }
                        )
                    )
                    .tint(.blue)

                    dueDateControl
                }

                Section(String(localized: "todo_tags")) {
                    HStack(spacing: 12) {
                        TextField(
                            String(localized: "todo_add"),
                            text: Binding(
                                get: { viewModel.state.tagText },
                                set: { viewModel.send(.setTagText($0)) }
                            )
                        )
                        .frame(height: UIFont.preferredFont(forTextStyle: .title2).lineHeight)
                        .textInputAutocapitalization(.never)
                        .focused($isTagFieldFocused)
                        .onSubmit {
                            submitTag()
                        }

                        if isTagFieldFocused {
                            Button {
                                submitTag()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(canSubmitTag ? .blue : .secondary)
                            }
                            .disabled(!canSubmitTag)
                        }
                    }

                    if viewModel.state.tags.isEmpty {
                        Text(String(localized: "todo_no_tags"))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        TagList(
                            viewModel.state.tags,
                            isEditing: isTagFieldFocused,
                            action: { viewModel.send(.removeTag($0)) }
                        )
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

    private var dueDateControl: some View {
        DueDatePicker(selection: Binding(
            get: { viewModel.state.dueDate ?? Date() },
            set: { viewModel.send(.setDueDate($0)) }
        )) {
            HStack {
                Text(String(localized: "todo_due_date"))
                    .foregroundStyle(.primary)
                Spacer()
                if let dueDate = viewModel.state.dueDate {
                    Tag(dueDateText(for: dueDate), isEditing: true) {
                        viewModel.send(.setDueDate(nil))
                    }
                    .padding(.vertical, -4)
                } else {
                    Text(String(localized: "todo_none"))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func submitTag() {
        guard canSubmitTag else { return }

        let tagText = normalizedTagText
        viewModel.send(.addTag(tagText))
        viewModel.send(.setTagText(""))
    }

    private var normalizedTagText: String {
        viewModel.state.tagText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmitTag: Bool {
        !normalizedTagText.isEmpty && !viewModel.state.tags.contains(normalizedTagText)
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

private struct DueDatePicker<Content: View>: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @State private var isPresented: Bool = false
    @State private var height: CGFloat = .pi
    @Binding var dueDate: Date
    @ViewBuilder private var content: () -> Content

    init(
        selection dueDate: Binding<Date>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._dueDate = dueDate
        self.content = content
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            content()
        }
        .sheet(isPresented: $isPresented) {
            DatePicker(
                "",
                selection: $dueDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.graphical)
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(height)])
            .background {
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        height = geometry.size.height + safeAreaInsets.bottom + safeAreaInsets.top
                    }
                }
            }
        }
    }
}
