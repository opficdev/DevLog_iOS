//
//  SettingsFeatureTestDoubles.swift
//  ProfileTabTests
//
//  Created by opfic on 6/12/26.
//

import Combine
import Core
import Domain

final class DeleteAuthUseCaseSpy: DeleteAuthUseCase {
    var error: Error?
    private(set) var executeCallCount = 0

    func execute() async throws {
        executeCallCount += 1

        if let error {
            throw error
        }
    }
}

final class SignOutUseCaseSpy: SignOutUseCase {
    var error: Error?
    var shouldSuspend = false
    private(set) var executeCallCount = 0
    private var continuation: CheckedContinuation<Void, Never>?
    private var shouldResume = false

    func execute() async throws {
        executeCallCount += 1

        if shouldSuspend {
            await withCheckedContinuation { continuation in
                if shouldResume {
                    shouldResume = false
                    continuation.resume()
                } else {
                    self.continuation = continuation
                }
            }
        }

        if let error {
            throw error
        }
    }

    func resume() {
        guard let continuation else {
            shouldResume = true
            return
        }

        self.continuation = nil
        continuation.resume()
    }
}

final class ObserveSystemThemeUseCaseSpy: ObserveSystemThemeUseCase {
    let subject = PassthroughSubject<SystemTheme, Never>()

    func observe() -> AnyPublisher<SystemTheme, Never> {
        subject.eraseToAnyPublisher()
    }
}

final class UpdateSystemThemeUseCaseSpy: UpdateSystemThemeUseCase {
    private(set) var themes = [SystemTheme]()

    func execute(_ theme: SystemTheme) {
        themes.append(theme)
    }
}

final class FetchWebPageImageDirSizeUseCaseSpy: FetchWebPageImageDirSizeUseCase {
    var dirSize: Int64
    private(set) var executeCallCount = 0

    init(dirSize: Int64 = 0) {
        self.dirSize = dirSize
    }

    func execute() async -> Int64 {
        executeCallCount += 1
        return dirSize
    }
}

final class ClearWebPageImageDirectoryUseCaseSpy: ClearWebPageImageDirectoryUseCase {
    var error: Error?
    private(set) var executeCallCount = 0

    func execute() async throws {
        executeCallCount += 1

        if let error {
            throw error
        }
    }
}

enum SettingsTestError: Error {
    case failure
}
