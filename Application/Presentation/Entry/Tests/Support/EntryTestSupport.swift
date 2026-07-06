//
//  EntryTestSupport.swift
//  PresentationTests
//
//  Created by opfic on 7/6/26.
//

import Domain

@MainActor
func waitUntil(
    timeout: Duration = .seconds(1),
    pollInterval: Duration = .milliseconds(20),
    _ condition: @escaping () -> Bool
) async {
    let continuousClock = ContinuousClock()
    let deadline = continuousClock.now + timeout

    while !condition() && continuousClock.now < deadline {
        try? await Task.sleep(for: pollInterval)
    }
}

final class SignInUseCaseSpy: SignInUseCase {
    var error: Error?
    var signedIn = true
    var shouldSuspend = false
    private(set) var calledProviders = [AuthProvider]()
    private(set) var successfulProviders = [AuthProvider]()
    private var continuation: CheckedContinuation<Void, Never>?
    private var shouldResume = false

    func execute(_ provider: AuthProvider) async throws -> Bool {
        calledProviders.append(provider)

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

        if signedIn {
            successfulProviders.append(provider)
        }

        return signedIn
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
