//
//  TodoDetailViewModel.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 2/15/26.
//

import Foundation
import DevLogDomain

@Observable
final class TodoDetailViewModel: StorePattern {
    struct State: Equatable {
        var todo: Todo?
        var selectedTodoId: TodoIdItem?
        var referenceItems: [Int: TodoReferenceItem] = [:]
        var isLoading: Bool  = false
        var showAlert: Bool  = false
        var showEditor: Bool  = false
        var showInfo: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
    }

    enum Action {
        case onAppear
        case setAlert(Bool)
        case setShowEditor(Bool)
        case setShowInfo(Bool)
        case setSelectedTodoId(TodoIdItem?)
        case setTodo(Todo)
        case setReferenceItems([Int: TodoReferenceItem])
        case setLoading(Bool)
    }

    enum SideEffect {
        case fetchTodo
        case resolveMarkdown(String)
    }

    private(set) var state: State = .init()
    let todoId: String
    let showEditButton: Bool
    private let fetchTodoUseCase: FetchTodoByIdUseCase
    private let fetchReferenceItemsUseCase: FetchReferenceItemsUseCase
    private let loadingState = LoadingState()

    init(
        fetchTodoUseCase: FetchTodoByIdUseCase,
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase,
        todoId: String,
        showEditButton: Bool = true
    ) {
        self.fetchTodoUseCase = fetchTodoUseCase
        self.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
        self.todoId = todoId
        self.showEditButton = showEditButton
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .onAppear:
            effects = [.fetchTodo]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .setShowEditor(let isPresented):
            state.showEditor = isPresented
        case .setShowInfo(let presented):
            state.showInfo = presented
        case .setSelectedTodoId(let todoId):
            state.selectedTodoId = todoId
        case .setTodo(let todo):
            state.todo = todo
            state.referenceItems = [:]
            effects = [.resolveMarkdown(todo.content)]
        case .setReferenceItems(let items):
            state.referenceItems = items
        case .setLoading(let value):
            state.isLoading = value
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchTodo:
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    let todo = try await fetchTodoUseCase.execute(todoId)
                    send(.setTodo(todo))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .resolveMarkdown(let content):
            Task {
                let numbers = content.todoReferenceNumbers
                var referenceItems = [Int: TodoReferenceItem]()

                if !numbers.isEmpty {
                    do {
                        referenceItems = try await fetchReferenceItemsUseCase.execute(numbers)
                            .mapValues(TodoReferenceItem.init(from:))
                    } catch {
                        referenceItems = [:]
                    }
                }

                send(.setReferenceItems(referenceItems))
            }
        }
    }
}

private extension TodoDetailViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
    }

    private func beginLoading(_ mode: LoadingState.Mode) {
        loadingState.begin(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }

    private func endLoading(_ mode: LoadingState.Mode) {
        loadingState.end(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }
}
