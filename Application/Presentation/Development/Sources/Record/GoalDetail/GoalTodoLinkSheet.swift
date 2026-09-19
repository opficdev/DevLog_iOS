//
//  GoalTodoLinkSheet.swift
//  Development
//
//  Created by opfic on 9/15/26.
//

import SwiftUI
import Domain
import PresentationShared

struct GoalTodoLinkSheet: View {
    @Bindable var store: StoreOf<GoalTodoLinkFeature>
    @ScaledMetric(relativeTo: .title) private var iconSize = UIFont.preferredFont(
        forTextStyle: .title2,
        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
    ).lineHeight

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                searchField
                sheetContent
                Text(RecordPresentation.text("development_goal_todo_optional_footer"))
                    .font(.footnote)
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(16)
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground.ignoresSafeArea())
        .overlay {
            if store.isUpdating {
                LoadingView()
            }
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(store.isUpdating)
    }

    private var topBar: some View {
        ZStack {
            Text(RecordPresentation.text("development_goal_todo_link_title"))
                .font(.headline)
            HStack {
                Button {
                    store.send(.view(.close))
                } label: {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "xmark")
                            .frame(width: iconSize, height: iconSize)
                            .font(.title)
                    } else {
                        Text(RecordPresentation.text("common_close"))
                    }
                }
                .topBarButtonStyle(color: Color.surface)
                .disabled(store.isUpdating)
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "ellipsis")
                        .font(.title3.weight(.semibold))
                        .frame(width: iconSize, height: iconSize)
                        .prominentMenu(
                            items: clearSelectionMenuItems,
                            isEnabled: store.canClearSelection
                        ) { _ in
                            store.send(.view(.clearSelection))
                        }
                        .topBarButtonStyle(color: Color.surface)
                    Button {
                        store.send(.view(.save))
                    } label: {
                        if #available(iOS 26.0, *) {
                            Image(systemName: "checkmark")
                                .frame(width: iconSize, height: iconSize)
                                .foregroundStyle(Color.primary)
                                .font(.title)
                        } else {
                            Text(RecordPresentation.text("development_goal_todo_done"))
                                .foregroundStyle(Color.accent)
                        }
                    }
                    .topBarButtonStyle(color: Color.surface)
                    .disabled(!store.canSave)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appBackground, ignoresSafeAreaEdges: .top)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textTertiary)
            TextField(
                RecordPresentation.text("development_goal_todo_search"),
                text: $store.searchText
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        .font(.title3)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
                .strokeBorder(Color.border, lineWidth: 1)
        }
    }

    private var clearSelectionMenuItems: [ProminentMenuItem<GoalTodoLinkMenuAction>] {
        [
            ProminentMenuItem(
                action: .clearSelection,
                title: RecordPresentation.text("development_goal_todo_clear_selection"),
                systemImage: "xmark.circle"
            )
        ]
    }

    @ViewBuilder
    private var sheetContent: some View {
        if store.isLoading, store.todos.isEmpty {
            ProgressView()
                .tint(Color.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if store.hasLoadFailure, store.todos.isEmpty {
            ContentUnavailableView {
                Label(
                    RecordPresentation.text("common_error_title"),
                    systemImage: "exclamationmark.triangle"
                )
            } description: {
                Text(RecordPresentation.text("development_goal_todo_load_error_message"))
            } actions: {
                Button(RecordPresentation.text("development_goal_todo_retry")) {
                    store.send(.view(.retry))
                }
                .buttonStyle(.borderedProminent)
            }
        } else if store.todos.isEmpty {
            ContentUnavailableView(
                RecordPresentation.text("development_goal_todo_available_empty_title"),
                systemImage: "checklist",
                description: Text(
                    RecordPresentation.text("development_goal_todo_available_empty_message")
                )
            )
        } else if store.filteredTodos.isEmpty {
            ContentUnavailableView.search(text: store.searchText)
        } else {
            ForEach(store.sections) { section in
                GoalTodoLinkSection(
                    section: section,
                    selectedTodoIDs: store.selectedTodoIDs,
                    onToggle: { store.send(.view(.toggleTodo($0))) }
                )
            }
        }
    }
}

private enum GoalTodoLinkMenuAction: Hashable {
    case clearSelection
}

private struct GoalTodoLinkSection: View {
    let section: GoalTodoLinkSectionItem
    let selectedTodoIDs: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: section.category.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 30, height: 30)
                    .background(section.category.color, in: .circle)
                Text(section.category.localizedName)
                    .font(.headline)
                Spacer()
            }

            LazyVStack(spacing: 0) {
                ForEach(section.todos, id: \.id) { todo in
                    GoalTodoLinkRow(
                        todo: todo,
                        isSelected: selectedTodoIDs.contains(todo.id)
                    ) {
                        onToggle(todo.id)
                    }
                }
            }
            .background(Color.surface)
            .compositingGroup()
            .clipShape(.rect(cornerRadius: 20))
        }
    }
}

private struct GoalTodoLinkRow: View {
    let todo: Todo
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? Color.accent : Color.border)
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text("#\(todo.number)")
                    Text(todo.dueDate ?? todo.updatedAt, format: .dateTime.month().day())
                }
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if todo.isPinned {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.warning)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.primaryContainer : .clear)
        .contentShape(.rect)
        .onTapGesture(perform: onToggle)
    }
}
