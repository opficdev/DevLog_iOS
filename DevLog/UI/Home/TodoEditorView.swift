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

private struct TagLayout: Layout {
    var verticalSpacing: CGFloat = 8
    var horizontalSpacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height =
        rows.reduce(0) { $0 + $1.maxHeight }
        + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var minY = bounds.minY

        for row in rows {
            var minX = bounds.minX

            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: minX, y: minY),
                    proposal: ProposedViewSize(size)
                )
                minX += size.width + horizontalSpacing
            }

            minY += row.maxHeight + verticalSpacing
        }
    }

    private func computeRows(
        maxWidth: CGFloat,
        subviews: Subviews
    ) -> [Row] {
        let availableWidth = maxWidth > 0 ? maxWidth : .infinity
        var rows: [Row] = []
        var currentRow = Row()
        var currentWidth: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if currentWidth + size.width > availableWidth && !currentRow.indices.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                currentWidth = 0
            }

            currentRow.indices.append(index)
            currentRow.maxHeight = max(currentRow.maxHeight, size.height)
            currentWidth += size.width + horizontalSpacing
        }

        if !currentRow.indices.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private struct Row {
        var indices: [Int] = []
        var maxHeight: CGFloat = 0
    }
}
