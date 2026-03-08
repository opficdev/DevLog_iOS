//
//  TodoDetailViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 2/15/26.
//

import Foundation

@Observable
final class TodoDetailViewModel: Store {
    struct State: Equatable {
        var todo: Todo?
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
        case setTodo(Todo)
        case setLoading(Bool)
        case upsertTodo(Todo)
    }

    enum SideEffect {
        case fetchTodo
        case upsertTodo(Todo)
    }

    private(set) var state: State = .init()
    let showEditButton: Bool
    private let fetchUseCase: FetchTodoByIdUseCase
    private let upsertUseCase: UpsertTodoUseCase
    private let todoId: String

    init(
        fetchUseCase: FetchTodoByIdUseCase,
        upsertUseCase: UpsertTodoUseCase,
        todoId: String,
        showEditButton: Bool = true
    ) {
        self.fetchUseCase = fetchUseCase
        self.upsertUseCase = upsertUseCase
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
        case .setTodo(let todo):
            state.todo = todo
        case .setLoading(let value):
            state.isLoading = value
        case .upsertTodo(let todo):
            effects = [.upsertTodo(todo)]
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchTodo:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let todo = try await fetchUseCase.execute(todoId)
                    send(.setTodo(todo))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .upsertTodo(let todo):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    try await upsertUseCase.execute(todo)
                    send(.setTodo(todo))
                } catch {
                    send(.setAlert(true))
                }
            }
        }
    }
}

private extension TodoDetailViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }
}
