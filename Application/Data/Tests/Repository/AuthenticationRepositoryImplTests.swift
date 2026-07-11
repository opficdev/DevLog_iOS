//
//  AuthenticationRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 7/11/26.
//

import Combine
import Foundation
import Testing
import Core
import Domain
@testable import Data

struct AuthenticationRepositoryImplTests {
    @Test("Apple 로그인 성공은 사용자 정보를 저장하고 로그인을 완료한다")
    func Apple_로그인_성공은_사용자_정보를_저장하고_로그인을_완료한다() async throws {
        let fixture = makeAuthenticationRepositoryFixture(
            signInResult: .success(makeAppleAuthDataResponse())
        )

        let result = try await fixture.repository.signIn(.apple)

        #expect(result)
        #expect(fixture.events.values() == [
            "auth.beginSignIn",
            "apple.signIn",
            "user.upsertUser",
            "auth.completeSignIn"
        ])
    }

    @Test("Apple 로그인 취소는 사용자 저장 없이 로그인을 취소한다")
    func Apple_로그인_취소는_사용자_저장_없이_로그인을_취소한다() async throws {
        let fixture = makeAuthenticationRepositoryFixture(signInResult: .success(nil))

        let result = try await fixture.repository.signIn(.apple)

        #expect(result == false)
        #expect(fixture.events.values() == [
            "auth.beginSignIn",
            "apple.signIn",
            "auth.cancelSignIn"
        ])
    }

    @Test("Apple 로그아웃은 provider 로그아웃 뒤 위젯 데이터를 정리한다")
    func Apple_로그아웃은_provider_로그아웃_뒤_위젯_데이터를_정리한다() async throws {
        let fixture = makeAuthenticationRepositoryFixture(
            uid: "user-id",
            providerID: "apple.com"
        )

        try await fixture.repository.signOut()

        #expect(fixture.events.values() == [
            "apple.signOut",
            "widget.clear"
        ])
    }

    @Test("Apple 회원탈퇴는 grant 정리 후 사용자와 세션과 위젯 데이터를 정리한다")
    func Apple_회원탈퇴는_grant_정리_후_사용자와_세션과_위젯_데이터를_정리한다() async throws {
        let fixture = makeAuthenticationRepositoryFixture(
            uid: "user-id",
            providerIDs: ["apple.com"]
        )

        try await fixture.repository.delete()

        #expect(fixture.events.values() == [
            "apple.deleteAuth",
            "auth.deleteCurrentUser",
            "auth.clearCurrentSession",
            "widget.clear"
        ])
    }

    @Test("Apple 회원탈퇴의 최근 로그인 오류는 세션 정리 없이 전달한다")
    func Apple_회원탈퇴의_최근_로그인_오류는_세션_정리_없이_전달한다() async {
        let fixture = makeAuthenticationRepositoryFixture(
            uid: "user-id",
            providerIDs: ["apple.com"],
            deleteCurrentUserError: AuthenticationRepositoryTestError.requiresRecentLogin
        )

        await #expect(throws: AuthenticationRepositoryTestError.requiresRecentLogin) {
            try await fixture.repository.delete()
        }
        #expect(fixture.events.values() == [
            "apple.deleteAuth",
            "auth.deleteCurrentUser"
        ])
    }

    private func makeAuthenticationRepositoryFixture(
        uid: String? = nil,
        providerID: String? = nil,
        providerIDs: [String] = [],
        signInResult: Result<AuthDataResponse?, Error> = .success(nil),
        deleteCurrentUserError: Error? = nil
    ) -> AuthenticationRepositoryFixture {
        let events = AuthenticationRepositoryEventRecorder()
        let authService = AuthenticationRepositoryAuthServiceSpy(
            uid: uid,
            providerID: providerID,
            providerIDs: providerIDs,
            deleteCurrentUserError: deleteCurrentUserError,
            events: events
        )
        let appleAuthService = AuthenticationServiceSpy(
            provider: "apple",
            signInResult: signInResult,
            events: events
        )
        let githubAuthService = AuthenticationServiceSpy(provider: "github", events: events)
        let googleAuthService = AuthenticationServiceSpy(provider: "google", events: events)
        let userService = AuthenticationRepositoryUserServiceSpy(events: events)
        let widgetSnapshotUpdater = AuthWidgetSnapshotUpdaterSpy(events: events)
        let repository = AuthenticationRepositoryImpl(
            authService: authService,
            appleAuthService: appleAuthService,
            githubAuthService: githubAuthService,
            googleAuthService: googleAuthService,
            userService: userService,
            widgetSnapshotUpdater: widgetSnapshotUpdater
        )

        return AuthenticationRepositoryFixture(
            events: events,
            repository: repository
        )
    }

    private func makeAppleAuthDataResponse() -> AuthDataResponse {
        AuthDataResponse(
            uid: "user-id",
            displayName: "Apple User",
            email: "apple@example.com",
            providers: ["apple.com"],
            providerID: "apple.com"
        )
    }
}

private struct AuthenticationRepositoryFixture {
    let events: AuthenticationRepositoryEventRecorder
    let repository: AuthenticationRepositoryImpl
}

private enum AuthenticationRepositoryTestError: Error, Equatable {
    case requiresRecentLogin
}

final class AuthenticationRepositoryEventRecorder {
    private let lock = NSLock()
    private var events = [String]()

    func record(_ event: String) {
        lock.withLock {
            events.append(event)
        }
    }

    func values() -> [String] {
        lock.withLock { events }
    }
}

final class AuthenticationRepositoryAuthServiceSpy: AuthService {
    private let subject: CurrentValueSubject<Bool, Never>
    private let providerID: String?
    private let deleteCurrentUserError: Error?
    private let events: AuthenticationRepositoryEventRecorder

    var uid: String?
    let providerIDs: [String]
    let currentUserEmail: String?
    let providerCount: Int

    init(
        uid: String?,
        providerID: String?,
        providerIDs: [String],
        currentUserEmail: String? = nil,
        providerCount: Int? = nil,
        deleteCurrentUserError: Error? = nil,
        events: AuthenticationRepositoryEventRecorder
    ) {
        self.uid = uid
        self.providerID = providerID
        self.providerIDs = providerIDs
        self.currentUserEmail = currentUserEmail
        self.providerCount = providerCount ?? providerIDs.count
        self.deleteCurrentUserError = deleteCurrentUserError
        self.events = events
        self.subject = CurrentValueSubject<Bool, Never>(uid != nil)
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func beginSignIn() {
        events.record("auth.beginSignIn")
    }

    func completeSignIn() {
        events.record("auth.completeSignIn")
    }

    func cancelSignIn() {
        events.record("auth.cancelSignIn")
    }

    func getProviderID() async throws -> String? {
        providerID
    }

    func deleteCurrentUser() async throws {
        events.record("auth.deleteCurrentUser")
        if let deleteCurrentUserError {
            throw deleteCurrentUserError
        }
    }

    func clearCurrentSession() async throws {
        events.record("auth.clearCurrentSession")
    }
}

actor AuthenticationServiceSpy: AuthenticationService {
    private let provider: String
    private let signInResult: Result<AuthDataResponse?, Error>
    private let linkResult: Result<Bool, Error>
    private let unlinkError: Error?
    private let events: AuthenticationRepositoryEventRecorder

    init(
        provider: String,
        signInResult: Result<AuthDataResponse?, Error> = .success(nil),
        linkResult: Result<Bool, Error> = .success(true),
        unlinkError: Error? = nil,
        events: AuthenticationRepositoryEventRecorder
    ) {
        self.provider = provider
        self.signInResult = signInResult
        self.linkResult = linkResult
        self.unlinkError = unlinkError
        self.events = events
    }

    func signIn() async throws -> AuthDataResponse? {
        events.record("\(provider).signIn")
        return try signInResult.get()
    }

    func signOut(_ uid: String) async throws {
        events.record("\(provider).signOut")
    }

    func deleteAuth(_ uid: String) async throws {
        events.record("\(provider).deleteAuth")
    }

    func link(uid: String, email: String) async throws -> Bool {
        events.record("\(provider).link")
        return try linkResult.get()
    }

    func unlink(_ uid: String) async throws {
        events.record("\(provider).unlink")
        if let unlinkError {
            throw unlinkError
        }
    }
}

private actor AuthenticationRepositoryUserServiceSpy: UserService {
    private let events: AuthenticationRepositoryEventRecorder

    init(events: AuthenticationRepositoryEventRecorder) {
        self.events = events
    }

    func upsertUser(_ response: AuthDataResponse) async throws {
        events.record("user.upsertUser")
    }

    func fetchUserProfile() async throws -> UserProfileResponse {
        fatalError("사용하지 않는 테스트 경로")
    }

    func upsertStatusMessage(_ message: String) async throws { }
    func updateFCMToken(_ fcmToken: String) async throws { }
    func updateUserTimeZone() async throws { }
}

private final class AuthWidgetSnapshotUpdaterSpy: WidgetSnapshotUpdater {
    private let events: AuthenticationRepositoryEventRecorder

    init(events: AuthenticationRepositoryEventRecorder) {
        self.events = events
    }

    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot]?,
        displayOptions: TodayDisplayOptions?,
        now: Date
    ) { }

    func updateHeatmapSnapshot(
        createdTodos: [WidgetTodoSnapshot]?,
        completedTodos: [WidgetTodoSnapshot]?,
        deletedTodos: [WidgetTodoSnapshot]?,
        quarterStart: Date?,
        now: Date
    ) { }

    func upsertTodoSnapshot(_ todo: WidgetTodoSnapshot, now: Date) { }
    func deleteTodoSnapshot(todoId: String, deletedAt: Date, now: Date) { }
    func restoreTodoSnapshot(todoId: String, now: Date) { }

    func clear() {
        events.record("widget.clear")
    }
}
