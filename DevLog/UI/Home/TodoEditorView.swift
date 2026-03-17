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
    @Environment(\.dismiss) private var dismiss
    @FocusState private var field: Field?
    @State private var showInfo: Bool = false
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
                field = .description
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.background, for: .navigationBar)
            .sheet(isPresented: $showInfo) {
                editorInfoSheet
            }
            .toolbar {
                ToolbarLeadingButton { dismiss() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInfo = true
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
                    field = .description
                }) {
                    Text("편집")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            viewModel.state.tabViewTag == .editor ? Color.primary : Color.secondary
                        )
                }
                Divider()
                Button(action: {
                    viewModel.send(.setTabViewTag(.preview))
                    field = nil
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
                    TextField(
                        "",
                        text: Binding(
                            get: { viewModel.state.content },
                            set: { viewModel.send(.setContent($0)) }
                        ),
                        prompt: Text("설명(선택)").foregroundColor(Color.secondary),
                        axis: .vertical
                    )
                    .font(.callout)
                    .focused($field, equals: .description)
                }
            } else {
                if viewModel.state.content.isEmpty {
                    previewPlaceholder
                } else {
                    Markdown(viewModel.state.content)
                        .markdownTheme(.basic)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var markdownHint: some View {
        Text("Markdown 지원 · 예: # 제목, - 목록, **굵게**")
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

    private var editorInfoSheet: some View {
        NavigationStack {
            List {
                Section("카테고리") {
                    Picker(
                        "카테고리",
                        selection: Binding(
                            get: { viewModel.state.kind },
                            set: { viewModel.send(.setKind($0)) }
                        )
                    ) {
                        ForEach(TodoKind.allCases) { todoKind in
                            Label(todoKind.localizedName, systemImage: todoKind.symbolName)
                                .tag(todoKind)
                        }
                    }
                }

                Section("옵션") {
                    Toggle(
                        "중요 표시",
                        isOn: Binding(
                            get: { viewModel.state.isPinned },
                            set: { isPinned in
                                if viewModel.state.isPinned != isPinned {
                                    viewModel.send(.togglePinned)
                                }
                            }
                        )
                    )

                    dueDateControl
                }

                Section("태그") {
                    TagEditor(
                        tags: viewModel.state.tags,
                        addAction: { viewModel.send(.addTag($0)) },
                        deleteAction: { viewModel.send(.removeTag($0)) }
                    ) {
                        Label("태그 편집", systemImage: "tag")
                    }

                    if viewModel.state.tags.isEmpty {
                        Text("태그 없음")
                            .foregroundStyle(.secondary)
                    } else {
                        TagList(viewModel.state.tags)
                            .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("세부 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarLeadingButton {
                    showInfo = false
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
                Label("마감일", systemImage: "calendar")
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

    private func submit() {
        let todo = viewModel.makeTodo()
        onSubmit?(todo)
        dismiss()
    }

    private enum Field: Hashable {
        case title, description, tag
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

private struct TagEditor<Content: View>: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @State private var isPresented: Bool = false
    @State private var sheetHeight: CGFloat = .pi
    @State private var tagsHeight: CGFloat = 0
    @State private var fieldHeight: CGFloat = 0
    @State private var tag = ""
    @ViewBuilder private var content: () -> Content
    private let tags: OrderedSet<String>
    private let addAction: (String) -> Void
    private let deleteAction: (String) -> Void
    private let spacing: CGFloat = 8

    init(
        tags: OrderedSet<String>,
        addAction: @escaping (String) -> Void = { _ in },
        deleteAction: @escaping (String) -> Void = { _ in },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tags = tags
        self.addAction = addAction
        self.deleteAction = deleteAction
        self.content = content
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            content()
        }
        .sheet(
            isPresented: $isPresented,
            onDismiss: { tag = "" }
        ) {
            VStack(spacing: tags.isEmpty ? 0 : spacing) {
                ScrollView {
                    TagList(tags, isEditing: true, action: deleteAction)
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        tagsHeight = geometry.size.height
                                        sheetHeight += tagsHeight + (tagsHeight == 0 ? 0 : spacing)
                                    }
                                }
                                .onChange(of: tags) { _, newTags in
                                    DispatchQueue.main.async {
                                        tagsHeight = geometry.size.height
                                        sheetHeight = fieldHeight + tagsHeight + (newTags.isEmpty ? 0 : spacing)
                                    }
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: tagsHeight)
                .padding(.top, tags.isEmpty ? 0 : 8)

                tagField
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    fieldHeight = geometry.size.height + 16
                                    sheetHeight = fieldHeight
                                }
                        }
                    }

            }
            .padding(.horizontal)
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(sheetHeight)])
        }
    }

    private var tagField: some View {
        HStack {
            HStack {
                TextField("태그 입력", text: $tag)
                    .keyboardType(.webSearch)
                    .padding(tag.isEmpty ? .all : [.leading, .vertical])
                    .onSubmit {
                        isPresented = false
                    }

                if !tag.isEmpty {
                    Button {
                        tag = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                Color(.label),
                                Color(.systemBackground)
                            )
                    }
                    .padding(.trailing)
                }
            }
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
            }

            Button {
                addAction(tag)
                tag = ""
            } label: {
                Image(systemName: "plus")
                    .font(.largeTitle)
                    .foregroundStyle(Color.white)
                    .adaptiveButtonStyle(
                        shape: .circle,
                        color: (!tag.isEmpty && !tags.contains(tag)) ? Color.blue : .gray.opacity(0.4)
                    )
            }
            .disabled(tag.isEmpty || tags.contains(tag))
        }
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
