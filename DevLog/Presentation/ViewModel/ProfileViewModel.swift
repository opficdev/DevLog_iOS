//
//  ProfileViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class ProfileViewModel: Store {
    struct State {
        var name: String = ""
        var email: String = ""
        var statusMessage: String = ""
        var avatarURL: URL?
        var showDoneButton: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var resetButtonEnabled: Bool {
            !statusMessage.isEmpty && showDoneButton
        }
    }

    enum Action {
        case onAppear
        case setAlert(Bool)
        case tapResetStatusMessageButton
        case willUpdateStatusMessage
        case fetchUserData(UserProfile)
        case updateStatusMessage(String)
        case updateStatusTextFieldFocus(Bool)
    }

    enum SideEffect {
        case fetchUserData
        case updateStatusMessage(String)
    }

    private let fetchUserDataUseCase: FetchUserDataUseCase
    private let upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    @Published private(set) var state = State()

    init(
        fetchUserDataUseCase: FetchUserDataUseCase,
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    ) {
        self.fetchUserDataUseCase = fetchUserDataUseCase
        self.upsertStatusMessageUseCase = upsertStatusMessageUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []
        switch action {
        case .onAppear:
            effects = [.fetchUserData]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .tapResetStatusMessageButton:
            state.statusMessage = ""
        case .fetchUserData(let profile):
            state.name = profile.name
            state.email = profile.email
            state.statusMessage = profile.statusMessage
            state.avatarURL = profile.avatarURL
        case .willUpdateStatusMessage:
            let message = self.state.statusMessage
            effects = [.updateStatusMessage(message)]
        case .updateStatusMessage(let message):
            state.statusMessage = message
        case .updateStatusTextFieldFocus(let focused):
            state.showDoneButton = focused
        }
        self.state = state
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchUserData:
            Task {
                do {
                    let profile = try await fetchUserDataUseCase.execute()
                    send(.fetchUserData(profile))
                } catch {
                    send(.setAlert(true))
                }
            }
        case .updateStatusMessage(let message):
            Task {
                do {
                    try await upsertStatusMessageUseCase.execute(message)
                } catch {
                    send(.setAlert(true))
                }
            }
        }
    }
}

private extension ProfileViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }
}
