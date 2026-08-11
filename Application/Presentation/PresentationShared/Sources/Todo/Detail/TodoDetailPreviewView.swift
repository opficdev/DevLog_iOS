//
//  TodoDetailPreviewView.swift
//  PresentationShared
//
//  Created by opfic on 8/11/26.
//

import SwiftUI
import ComposableArchitecture

struct TodoDetailPreviewView: View {
    @State var store: StoreOf<TodoDetailFeature>

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            if let todo = store.todo {
                TodoDetailContentView(
                    title: todo.title,
                    content: todo.content,
                    referenceItems: store.referenceItems,
                    number: todo.number,
                    onOpenTodoID: nil
                )
            } else if store.alert != nil {
                ContentUnavailableView {
                    Label(
                        String(localized: "common_error_title"),
                        systemImage: "exclamationmark.triangle"
                    )
                } description: {
                    Text(String(localized: "common_error_message"))
                }
            } else {
                LoadingView()
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
