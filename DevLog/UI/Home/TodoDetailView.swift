//
//  TodoDetailView.swift
//  DevLog
//
//  Created by opfic on 6/12/25.
//

import SwiftUI

struct TodoDetailView: View {
    @StateObject var viewModel: TodoDetailViewModel

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()
            if let todo = viewModel.state.todo {
                TodoDetailContentView(
                    title: todo.title,
                    content: todo.content
                )
            } else if viewModel.state.isLoading {
                LoadingView()
            }
        }
        .onAppear { viewModel.send(.onAppear) }
        .sheet(isPresented: Binding(
            get: { viewModel.state.showInfo },
            set: { viewModel.send(.setShowInfo($0)) }
        )) {
            sheetContent
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.state.showEditor },
            set: { viewModel.send(.setShowEditor($0)) }
        )) {
            if let todo = viewModel.state.todo {
                TodoEditorView(
                    viewModel: TodoEditorViewModel(todo: todo),
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

    private var sheetContent: some View {
        TodoInfoSheetView(
            dueDate: viewModel.state.todo?.dueDate,
            tags: viewModel.state.todo?.tags ?? []
        ) {
            viewModel.send(.setShowInfo(false))
        }
    }
}
