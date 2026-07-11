//
//  AuthDataRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 7/11/26.
//

import Testing
import Domain
@testable import Data

struct AuthDataRepositoryImplTests {
    @Test("Apple 계정 연결 취소는 false를 반환한다")
    func Apple_계정_연결_취소는_false를_반환한다() async throws {
        let fixture = makeFixture(linkResult: .success(false))

        let result = try await fixture.repository.linkProvider(.apple)

        #expect(result == false)
        #expect(fixture.events.values() == ["apple.link"])
    }

    @Test("Apple 계정 연결의 이메일 없음 오류를 기존 앱 오류로 변환한다")
    func Apple_계정_연결의_이메일_없음_오류를_기존_앱_오류로_변환한다() async {
        let fixture = makeFixture(linkResult: .failure(EmailError.notFound))

        await expectAuthError(.linkEmailNotFound) {
            _ = try await fixture.repository.linkProvider(.apple)
        }
    }

    @Test("Apple 계정 연결의 이메일 불일치 오류를 기존 앱 오류로 변환한다")
    func Apple_계정_연결의_이메일_불일치_오류를_기존_앱_오류로_변환한다() async {
        let fixture = makeFixture(linkResult: .failure(EmailError.mismatch))

        await expectAuthError(.linkEmailMismatch) {
            _ = try await fixture.repository.linkProvider(.apple)
        }
    }

    @Test("Apple 계정 연결 충돌을 기존 app credential 오류로 변환한다")
    func Apple_계정_연결_충돌을_기존_app_credential_오류로_변환한다() async {
        let fixture = makeFixture(
            linkResult: .failure(DataLayerError.linkCredentialAlreadyInUse)
        )

        await expectAuthError(.linkCredentialAlreadyInUse) {
            _ = try await fixture.repository.linkProvider(.apple)
        }
    }

    @Test("Apple 마지막 provider 연결 해제는 서비스 호출 전에 차단한다")
    func Apple_마지막_provider_연결_해제는_서비스_호출_전에_차단한다() async {
        let fixture = makeFixture(providerCount: 1)

        await expectAuthError(.failedToUnlinkLastProvider) {
            try await fixture.repository.unlinkProvider(.apple)
        }
        #expect(fixture.events.values().isEmpty)
    }

    @Test("Apple 서버의 마지막 provider 오류를 기존 앱 오류로 변환한다")
    func Apple_서버의_마지막_provider_오류를_기존_앱_오류로_변환한다() async {
        let fixture = makeFixture(
            unlinkError: DataLayerError.failedToUnlinkLastProvider
        )

        await expectAuthError(.failedToUnlinkLastProvider) {
            try await fixture.repository.unlinkProvider(.apple)
        }
    }

    @Test("Apple 계정 연결 해제는 Apple 서비스를 호출한다")
    func Apple_계정_연결_해제는_Apple_서비스를_호출한다() async throws {
        let fixture = makeFixture()

        try await fixture.repository.unlinkProvider(.apple)

        #expect(fixture.events.values() == ["apple.unlink"])
    }

    private func makeFixture(
        providerCount: Int = 2,
        linkResult: Result<Bool, Error> = .success(true),
        unlinkError: Error? = nil
    ) -> AuthDataRepositoryFixture {
        let events = AuthenticationRepositoryEventRecorder()
        let authService = AuthenticationRepositoryAuthServiceSpy(
            uid: "user-id",
            providerID: "apple.com",
            providerIDs: ["apple.com", "google.com"],
            currentUserEmail: "apple@example.com",
            providerCount: providerCount,
            events: events
        )
        let appleAuthService = AuthenticationServiceSpy(
            provider: "apple",
            linkResult: linkResult,
            unlinkError: unlinkError,
            events: events
        )
        let githubAuthService = AuthenticationServiceSpy(provider: "github", events: events)
        let googleAuthService = AuthenticationServiceSpy(provider: "google", events: events)
        let repository = AuthDataRepositoryImpl(
            authService: authService,
            appleAuthService: appleAuthService,
            githubAuthService: githubAuthService,
            googleAuthService: googleAuthService
        )

        return AuthDataRepositoryFixture(
            events: events,
            repository: repository
        )
    }

    private func expectAuthError(
        _ expected: AuthError,
        operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            Issue.record("예상한 AuthError가 발생하지 않음")
        } catch let error as AuthError {
            #expect(String(describing: error) == String(describing: expected))
        } catch {
            Issue.record("예상하지 않은 오류: \(error)")
        }
    }
}

private struct AuthDataRepositoryFixture {
    let events: AuthenticationRepositoryEventRecorder
    let repository: AuthDataRepositoryImpl
}
