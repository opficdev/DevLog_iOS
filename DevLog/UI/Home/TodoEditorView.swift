//
//  TodoEditorView.swift
//  DevLog
//
//  Created by opfic on 5/31/25.
//

import SwiftUI
import MarkdownUI

struct TodoEditorView: View {
    @StateObject var viewModel: TodoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var field: Field?
    @State private var showDueDatePicker: Bool = false
    var onSubmit: ((Todo) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
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
                HStack {
                    Button {
                        field = nil
                    } label: {
                        Label {
                            Text("태그")
                        } icon: {
                            Image(systemName: "tag")
                                .foregroundStyle(.gray)
                        }
                    }
                    .adaptiveButtonStyle()

                    Button {
                        field = nil
                        showDueDatePicker = true
                    } label: {
                        Label {
                            Text("마감일")
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.gray)
                        }
                    }
                    .adaptiveButtonStyle()
                }
                .padding(.bottom, 16 + safeAreaInsets.bottom / 4)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolBar }
        }
    }

    private var titleField: some View {
        TextField(
            "",
            text: Binding(
                get: { viewModel.state.title },
                set: { viewModel.send(.setTitle($0)) }
            ),
            prompt: Text("제목").foregroundColor(Color.gray)
        )
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
            .background(Color(UIColor.systemBackground))
        }
    }

    private var tabView: some View {
        Group {
            if viewModel.state.tabViewTag == .editor {
                TextField(
                    "",
                    text: Binding(
                        get: { viewModel.state.content },
                        set: { viewModel.send(.setContent($0)) }
                    ),
                    prompt: Text("설명(선택 사항)").font(.callout),
                    axis: .vertical
                )
                .focused($field, equals: .description)
            } else {
                Markdown(viewModel.state.content)
                    .markdownTheme(.basic)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    @ToolbarContentBuilder
    private var toolBar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")}
            .bold()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                onSubmit?(viewModel.upsertTodo())
                dismiss()
            }) {
                Text("추가")
            }
            .disabled(!viewModel.state.isValidToSave)
        }
    }

    private enum Field: Hashable {
        case title, description, tag
    }
}


        self.action = action
    }

    var body: some View {
                    }
                }
            }
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
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(height)])
            .background {
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        height = geometry.size.height + safeAreaInsets.bottom + 16
                    }
                }
            }
        }
    }
}
