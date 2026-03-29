//
//  TodoEditorView.swift
//  DevLog
//
//  Created by opfic on 5/31/25.
//

import MarkdownUI
import OrderedCollections
import SwiftUI

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
            prompt: Text("제목(필수)").foregroundColor(Color.secondary),
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
                    Text("편집")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            viewModel.state.tabViewTag == .editor ? Color.primary : Color.secondary
                        )
                }
                Divider()
                Button(action: {
                    transitionToPreview()
                }) {
                    Text("미리보기")
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
                        placeholder: "설명(선택)"
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
        Text("Markdown 지원 · 예: # 제목, - 목록, **굵게**, - refs #번호")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var previewPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Markdown 미리보기")
                .font(.subheadline.weight(.semibold))
            Text("편집 탭에서 Markdown으로 작성하면 여기에서 서식이 적용되어 보여요.")
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
                Section("옵션") {
                    Picker(
                        "카테고리",
                        selection: Binding(
                            get: { viewModel.state.category },
                            set: { viewModel.send(.setCategory($0)) }
                        )
                    ) {
                        ForEach(SystemTodoCategory.allCases) { category in
                            Text(category.localizedName)
                                .tag(TodoCategory.system(category))
                        }
                    }

                    Toggle(
                        "완료",
                        isOn: Binding(
                            get: { viewModel.state.isCompleted },
                            set: { viewModel.send(.setCompleted($0)) }
                        )
                    )
                    .tint(.blue)

                    Toggle(
                        "중요 표시",
                        isOn: Binding(
                            get: { viewModel.state.isPinned },
                            set: { viewModel.send(.setPinned($0)) }
                        )
                    )
                    .tint(.blue)

                    dueDateControl
                }

                Section("태그") {
                    HStack(spacing: 12) {
                        TextField(
                            "추가",
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
                        Text("태그 없음")
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
            .navigationTitle("세부 정보")
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
                Text("마감일")
                    .foregroundStyle(.primary)
                Spacer()
                if let dueDate = viewModel.state.dueDate {
                    Tag(dueDateText(for: dueDate), isEditing: true) {
                        viewModel.send(.setDueDate(nil))
                    }
                    .padding(.vertical, -4)
                } else {
                    Text("없음")
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
