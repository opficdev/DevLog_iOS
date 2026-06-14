//
//  HomeFeature+Effects.swift
//  DevLogPresentation
//
//  Created by opfic on 6/14/26.
//

import Combine
import ComposableArchitecture
import DevLogCore
import DevLogDomain
import Foundation

extension HomeFeature {
    private enum CancelID: Hashable {
        case delayedModal(ModalType)
        case networkConnectivity
    }

    func observeNetworkConnectivityEffect() -> Effect<Action> {
        .publisher { [networkConnectivityUseCase] in
            networkConnectivityUseCase.observe()
                .receive(on: DispatchQueue.main)
                .map(Action.networkStatusChanged)
        }
        .cancellable(id: CancelID.networkConnectivity, cancelInFlight: true)
    }

    func fetchTodoCategoryPreferencesEffect() -> Effect<Action> {
        .run { [fetchPreferencesUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.preferences.target, mode: .immediate)))
            do {
                let preferences = try await fetchPreferencesUseCase.execute()
                await send(.store(.setTodoCategory(preferences.map(TodoCategoryItem.init(from:)))))
            } catch {
                await send(.setAlert(isPresented: true, type: .error))
            }
            await send(.loading(.end(target: LoadingTarget.preferences.target, mode: .immediate)))
        }
    }

    func fetchRecentTodosEffect() -> Effect<Action> {
        .run { [fetchTodosUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.recentTodos.target, mode: .immediate)))
            do {
                let page = try await fetchRecentTodos(fetchTodosUseCase: fetchTodosUseCase)
                let items = page.items
                    .filter { $0.createdAt != $0.updatedAt }
                    .prefix(5)
                    .compactMap(RecentTodoItem.init(from:))
                await send(.store(.updateRecentTodos(Array(items))))
            } catch {
                await send(.setAlert(isPresented: true, type: .error))
            }
            await send(.loading(.end(target: LoadingTarget.recentTodos.target, mode: .immediate)))
        }
    }

    func fetchWebPagesEffect() -> Effect<Action> {
        .run { [fetchWebPagesUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.webPage.target, mode: .immediate)))
            do {
                let pages = try await fetchWebPagesUseCase.execute("")
                await send(.store(.updateWebPages(pages.map(WebPageItem.init(from:)))))
            } catch {
                await send(.setAlert(isPresented: true, type: .error))
            }
            await send(.loading(.end(target: LoadingTarget.webPage.target, mode: .immediate)))
        }
    }

    func addWebPageEffect(_ urlString: String) -> Effect<Action> {
        .run { [addWebPageUseCase, fetchWebPagesUseCase, trackAnalyticsEventUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.overlay.target, mode: .delayed)))
            do {
                try await addWebPageUseCase.execute(urlString)
                trackAnalyticsEventUseCase?.execute(.webPageCreate)
                let pages = try await fetchWebPagesUseCase.execute("")
                await send(.store(.updateWebPages(pages.map(WebPageItem.init(from:)))))
            } catch {
                await send(.setAlert(isPresented: true, type: .error))
            }
            await send(.loading(.end(target: LoadingTarget.overlay.target, mode: .delayed)))
        }
    }

    func deleteWebPageEffect(_ page: WebPageItem) -> Effect<Action> {
        .run { [deleteWebPageUseCase] send in
            do {
                try await deleteWebPageUseCase.execute(page.url.absoluteString)
            } catch {
                await send(.handleWebPageDeleteFailure(page.id))
                await send(.setAlert(isPresented: true, type: .error))
            }
        }
    }

    func undoDeleteWebPageEffect(_ urlString: String) -> Effect<Action> {
        .run { [undoDeleteWebPageUseCase, addWebPageUseCase] send in
            do {
                try await undoDeleteWebPageUseCase.execute(urlString)
                try await addWebPageUseCase.execute(urlString)
            } catch {
                if let webPageURL = URL(string: urlString) {
                    await send(.setWebPageHidden(webPageURL, true))
                }
                await send(.setAlert(isPresented: true, type: .error))
            }
        }
    }

    func updateTodoCategoryPreferencesEffect(_ items: [TodoCategoryItem]) -> Effect<Action> {
        .run { [updatePreferencesUseCase] send in
            do {
                try await updatePreferencesUseCase.execute(items.map(\.preference))
            } catch {
                await send(.setAlert(isPresented: true, type: .error))
            }
        }
    }

    func delayedModalEffect(_ type: ModalType) -> Effect<Action> {
        .run { [clock] send in
            try await clock.sleep(for: .seconds(0.1))
            switch type {
            case .todoEditor:
                await send(.setPresentation(.todoEditor, true))
            case .urlInputAlert:
                await send(.setAlert(isPresented: true, type: .webPageInput))
            }
        }
        .cancellable(id: CancelID.delayedModal(type), cancelInFlight: true)
    }

    func fetchRecentTodos(fetchTodosUseCase: FetchTodosUseCase) async throws -> TodoPage {
        try await fetchTodosUseCase.execute(
            TodoQuery(
                sortTarget: .updatedAt,
                sortOrder: .latest,
                pageSize: 100
            ),
            cursor: nil
        )
    }

    static func setPresentation(
        _ state: inout State,
        presentation: Presentation,
        isPresented: Bool
    ) {
        switch presentation {
        case .reorderTodo:
            state.sheet = isPresented ? .reorderTodo : state.sheet == .reorderTodo ? nil : state.sheet
        case .todoEditor:
            state.showTodoEditor = isPresented
            if !isPresented {
                state.selectedTodoCategory = nil
            }
        case .contentPicker:
            state.sheet = isPresented ? .contentPicker : state.sheet == .contentPicker ? nil : state.sheet
        case .searchView:
            state.showSearchView = isPresented
        }
    }

    static func setAlert(
        _ state: inout State,
        isPresented: Bool,
        type: AlertType?
    ) {
        switch type {
        case .webPageInput:
            state.alertTitle = String(localized: "home_webpage_input_title")
            state.alertMessage = String(localized: "home_webpage_input_message")
            state.webPageURLInput = "https://"
        case .invalidURL:
            state.alertTitle = String(localized: "home_invalid_url_title")
            state.alertMessage = String(localized: "home_invalid_url_message")
        case .error:
            state.alertTitle = String(localized: "common_error_title")
            state.alertMessage = String(localized: "common_error_message")
        case .none:
            state.alertTitle = ""
            state.alertMessage = ""
        }

        state.showAlert = isPresented
        state.alertType = type
    }

    static func syncRecentTodos(
        _ recentTodos: [RecentTodoItem],
        preferences: [TodoCategoryItem]
    ) -> [RecentTodoItem] {
        recentTodos.map { recentTodo in
            guard let item = preferences.first(where: {
                $0.category.storageValue == recentTodo.category.storageValue
            }) else {
                return recentTodo
            }

            var recentTodo = recentTodo
            recentTodo.category = item.category
            return recentTodo
        }
    }

    static func normalizedWebPageURL(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed == "https://" || trimmed == "http://" {
            return nil
        }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }
}
