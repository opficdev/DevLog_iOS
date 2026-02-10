//
//  NotificationViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class PushNotificationViewModel: Store {
    struct State {
        var notifications: [PushNotification] = []
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertType: AlertType?
        var alertMessage: String = ""
        var isLoading: Bool = false
    }

    enum Action {
        case fetchNotifications
        case deleteNotification(PushNotification, fromEffect: Bool = false)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
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
        case .deleteNotification(let item, let fromEffect):
            if !fromEffect { return [.delete(item)] }
            state.notifications.removeAll { $0.id == item.id }
        case .setAlert(let isPresented, let type):
            setAlert(isPresented: isPresented, for: type)
            return []
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
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    try await deleteUseCase.execute(notification.id)
                    send(.deleteNotification(notification, fromEffect: true))
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
}
