//
//  TodoDetailFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/11/26.
//

import ComposableArchitecture
import DevLogDomain
import Foundation

@Reducer
struct TodoDetailFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        @Presents var sheet: SheetState?
        @Presents var fullScreenCover: FullScreenCoverState?
        var todoId: String
        var showEditButton: Bool
        var todo: Todo?
        var referenceItems: [Int: TodoReferenceItem] = [:]
        var isLoading = false
    }

    @ObservableState
    struct SheetState: Equatable {
        var destination: Destination

        var todoDetail: TodoDetailFeature.State? {
            get {
                guard case .todo(let state) = destination else { return nil }
                return state
            }
            set {
                guard let newValue else { return }
                destination = .todo(newValue)
            }
        }

        enum Destination: Equatable {
            case info
            case todo(TodoDetailFeature.State)
        }

        static let info = Self(destination: .info)

        static func todo(_ todoId: TodoIdItem) -> Self {
            Self(
                destination: .todo(
                    TodoDetailFeature.State(
                        todoId: todoId.id,
                        showEditButton: false
                    )
                )
            )
        }
    }

    @ObservableState
    struct FullScreenCoverState: Equatable {
        var destination: Destination

        enum Destination: Equatable {
            case editor
        }

        static let editor = Self(destination: .editor)
    }

    enum Action {
        case alert(PresentationAction<Never>)
        case sheet(PresentationAction<Sheet>)
        case fullScreenCover(PresentationAction<Never>)
        case onAppear
        case fetchFailed
        case setSheet(SheetState?)
        case setFullScreenCover(FullScreenCoverState?)
        case setTodo(Todo)
        case setReferenceItems([Int: TodoReferenceItem])
        case setLoading(Bool)

        @CasePathable
        enum Sheet {
            case tapCloseButton
            case todo(TodoDetailFeature.Action)
        }
    }

    @Dependency(\.fetchTodoByIdUseCase) var fetchTodoUseCase
    @Dependency(\.fetchReferenceItemsUseCase) var fetchReferenceItemsUseCase
    private let loadingState = LoadingState()

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .sheet(.dismiss):
                state.sheet = nil
            case .alert:
                break
            case .sheet(.presented(.tapCloseButton)):
                state.sheet = nil
            case .sheet:
                break
            case .fullScreenCover(.dismiss):
                state.fullScreenCover = nil
            case .fullScreenCover:
                break
            case .onAppear:
                return fetchTodoEffect(todoId: state.todoId)
            case .fetchFailed:
                state.alert = alertState()
            case .setSheet(let sheet):
                state.sheet = sheet
            case .setFullScreenCover(let cover):
                state.fullScreenCover = cover
            case .setTodo(let todo):
                state.todo = todo
                state.referenceItems = [:]
                return resolveMarkdownEffect(content: todo.content)
            case .setReferenceItems(let items):
                state.referenceItems = items
            case .setLoading(let value):
                state.isLoading = value
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$sheet, action: \.sheet) {
            TodoDetailSheetFeature()
        }
    }
}

private struct TodoDetailSheetFeature: Reducer {
    typealias State = TodoDetailFeature.SheetState
    typealias Action = TodoDetailFeature.Action.Sheet

    var body: some ReducerOf<Self> {
        EmptyReducer()
        .ifLet(\.todoDetail, action: \.todo) {
            TodoDetailFeature()
        }
    }
}

extension DependencyValues {
    var fetchTodoByIdUseCase: FetchTodoByIdUseCase {
        get { self[FetchTodoByIdUseCaseKey.self] }
        set { self[FetchTodoByIdUseCaseKey.self] = newValue }
    }

    var fetchReferenceItemsUseCase: FetchReferenceItemsUseCase {
        get { self[FetchReferenceItemsUseCaseKey.self] }
        set { self[FetchReferenceItemsUseCaseKey.self] = newValue }
    }
}

private enum FetchTodoByIdUseCaseKey: DependencyKey {
    static var liveValue: FetchTodoByIdUseCase {
        preconditionFailure("FetchTodoByIdUseCase must be provided.")
    }

    static var testValue: FetchTodoByIdUseCase {
        liveValue
    }
}

private enum FetchReferenceItemsUseCaseKey: DependencyKey {
    static var liveValue: FetchReferenceItemsUseCase {
        preconditionFailure("FetchReferenceItemsUseCase must be provided.")
    }

    static var testValue: FetchReferenceItemsUseCase {
        liveValue
    }
}

private extension TodoDetailFeature {
    func fetchTodoEffect(todoId: String) -> Effect<Action> {
        .run { [fetchTodoUseCase, loadingState] send in
            await loadingState.begin(mode: .delayed) { isLoading in
                send(.setLoading(isLoading))
            }
            do {
                let todo = try await fetchTodoUseCase.execute(todoId)
                await loadingState.end(mode: .delayed) { isLoading in
                    send(.setLoading(isLoading))
                }
                await send(.setTodo(todo))
            } catch {
                await loadingState.end(mode: .delayed) { isLoading in
                    send(.setLoading(isLoading))
                }
                await send(.fetchFailed)
            }
        }
    }

    func resolveMarkdownEffect(content: String) -> Effect<Action> {
        .run { [fetchReferenceItemsUseCase] send in
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

            await send(.setReferenceItems(referenceItems))
        }
    }

    func alertState() -> AlertState<Never> {
        AlertState {
            TextState(String(localized: "common_error_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close"))
            }
        } message: {
            TextState(String(localized: "common_error_message"))
        }
    }
}
