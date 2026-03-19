//
//  AuthSessionRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

import Combine
import Foundation

final class AuthSessionRepositoryImpl: AuthSessionRepository {
    private let userDefaultsStore: UserDefaultsStore
    private var cancellables = Set<AnyCancellable>()
    private let signInSubject: CurrentValueSubject<Bool, Never>

    init(authService: AuthService, userDefaultsStore: UserDefaultsStore) {
        self.userDefaultsStore = userDefaultsStore
        self.signInSubject = .init(authService.uid != nil)

        authService.signedInPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signIn in
                self?.applySession(signIn)
            }
            .store(in: &cancellables)
    }

    var signedInPublisher: AnyPublisher<Bool, Never> {
        signInSubject.eraseToAnyPublisher()
    }
}

private extension AuthSessionRepositoryImpl {
    func applySession(_ signedIn: Bool) {
        if signInSubject.value && !signedIn {
            userDefaultsStore.removeAll()
        }
        signInSubject.send(signedIn)
    }
}
