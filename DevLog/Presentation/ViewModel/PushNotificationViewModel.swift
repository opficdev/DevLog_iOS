//
//  PushNotificationViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class PushNotificationViewModel: Store {
    struct State {
        var notifications: [PushNotification] = []
        var showAlert: Bool = false
        var showToast: Bool = false
        var alertTitle: String = ""
        var alertType: AlertType?
        var alertMessage: String = ""
        var toastMessage: String = ""
        var toastType: ToastType?
        var isLoading: Bool = false
        var pendingTask: (PushNotification, Int)?
    }

    enum Action {
        case fetchNotifications
        case deleteNotification(PushNotification)
        case undoDelete
        case confirmDelete
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case setLoading(Bool)
        case setNotifications([PushNotification])
    }

    enum SideEffect {
        case fetch
        case delete(PushNotification)
    }

    enum AlertType {
        case error
    }

    enum ToastType {
        case delete
    }

    @Published private(set) var state: State = .init()
    private let fetchUseCase: FetchPushNotificationsUseCase
    private let deleteUseCase: DeletePushNotificationUseCase

    init(
        fetchUseCase: FetchPushNotificationsUseCase,
        deleteUseCase: DeletePushNotificationUseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state

        switch action {
        case .fetchNotifications:
            return [.fetch]
        case .deleteNotification(let item):
            guard let index = state.notifications.firstIndex(where: { $0.id == item.id }) else {
                return []
            }
            state.pendingTask = (item, index)
            state.notifications.remove(at: index)
            setToast(&state, isPresented: true, for: .delete)
        case .undoDelete:
            guard let (item, index) = state.pendingTask else { return [] }
            state.notifications.insert(item, at: index)
            state.pendingTask = nil
        case .confirmDelete:
            guard let (item, _ ) = state.pendingTask else {
                return []
            }
            return [.delete(item)]
        case .setAlert(let isPresented, let type):
            setAlert(isPresented: isPresented, for: type)
            return []
        case .setToast(let isPresented, let type):
            setToast(&state, isPresented: isPresented, for: type)
        case .setLoading(let value):
            state.isLoading = value
        case .setNotifications(let notifications):
            state.notifications = notifications
        }

        self.state = state
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetch:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let notifications = try await fetchUseCase.execute()
                    send(.setNotifications(notifications))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .delete(let notification):
            Task {
                do {
                    try await deleteUseCase.execute(notification.id)
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        }
    }
}

private extension PushNotificationViewModel {
    func setAlert(isPresented: Bool, for type: AlertType?) {
        switch type {
        case .error:
            state.alertTitle = "오류"
            state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        case .none:
            state.alertTitle = ""
            state.alertMessage = ""
        }
        state.alertType = type
        state.showAlert = isPresented
    }

    func setToast(
        _ state: inout State,
        isPresented: Bool,
        for type: ToastType?
    ) {
        switch type {
        case .delete:
            state.toastMessage = "실행 취소"
        case .none:
            state.toastMessage = ""
        }
        state.showToast = isPresented
    }
}
