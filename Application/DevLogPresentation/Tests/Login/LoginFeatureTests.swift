//
//  LoginFeatureTests.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/5/26.
//

import Testing
import ComposableArchitecture
import Foundation
import DevLogDomain
@testable import DevLogPresentation

@MainActor
struct LoginFeatureTests {
    @Test("로그인 버튼을 누르면 선택한 인증 제공자로 로그인 유스케이스가 호출된다")
    func 로그인_버튼을_누르면_선택한_인증_제공자로_로그인_유스케이스가_호출된다() async {
        let spy = SignInUseCaseSpy()
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.github)

        await waitUntil {
            spy.calledProviders == [.github]
        }

        #expect(spy.calledProviders == [.github])
    }

    @Test("로그인 요청 중에는 로딩 상태가 켜지고 요청이 끝나면 꺼진다")
    func 로그인_요청_중에는_로딩_상태가_켜지고_요청이_끝나면_꺼진다() async {
        let spy = SignInUseCaseSpy()
        spy.shouldSuspend = true
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.google)

        await waitUntil {
            driver.isLoading
        }

        #expect(driver.isLoading)

        spy.resume()

        await waitUntil {
            !driver.isLoading
        }

        #expect(!driver.isLoading)
    }

    @Test("로그인 실패 후에도 로딩 상태가 꺼진다")
    func 로그인_실패_후에도_로딩_상태가_꺼진다() async {
        let spy = SignInUseCaseSpy()
        spy.shouldSuspend = true
        spy.error = AuthError.unsupportedProvider
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.apple)

        await waitUntil {
            driver.isLoading
        }

        #expect(driver.isLoading)

        spy.resume()

        await waitUntil {
            !driver.isLoading && driver.showAlert
        }

        #expect(!driver.isLoading)
    }

    @Test("이메일을 가져오지 못하면 이메일 없음 알림을 표시한다")
    func 이메일을_가져오지_못하면_이메일_없음_알림을_표시한다() async {
        let spy = SignInUseCaseSpy()
        spy.error = AuthError.emailNotFound
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.google)

        await waitUntil {
            driver.showAlert
        }

        #expect(driver.alertKind == .emailUnavailable)
        #expect(driver.alertTitle == String(localized: "login_alert_email_unavailable_title"))
        #expect(driver.alertMessage == String(localized: "login_alert_email_unavailable_message"))
    }

    @Test("일반 로그인 에러가 발생하면 공통 에러 알림을 표시한다")
    func 일반_로그인_에러가_발생하면_공통_에러_알림을_표시한다() async {
        let spy = SignInUseCaseSpy()
        spy.error = AuthError.unsupportedProvider
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.apple)

        await waitUntil {
            driver.showAlert
        }

        #expect(driver.alertKind == .error)
        #expect(driver.alertTitle == String(localized: "common_error_title"))
        #expect(driver.alertMessage == String(localized: "common_error_message"))
    }

    @Test("소셜 로그인 취소 에러가 발생하면 알림을 표시하지 않는다")
    func 소셜_로그인_취소_에러가_발생하면_알림을_표시하지_않는다() async {
        let spy = SignInUseCaseSpy()
        spy.error = NSError(domain: "com.google.GIDSignIn", code: -5)
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.google)

        await waitUntil {
            spy.calledProviders == [.google] && !driver.isLoading
        }

        #expect(!driver.showAlert)
        #expect(driver.alertKind == nil)
        #expect(driver.alertTitle.isEmpty)
        #expect(driver.alertMessage.isEmpty)
    }

    @Test("알림을 닫으면 알림 상태와 문구가 초기화된다")
    func 알림을_닫으면_알림_상태와_문구가_초기화된다() async {
        let spy = SignInUseCaseSpy()
        spy.error = AuthError.emailNotFound
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.google)

        await waitUntil {
            driver.showAlert
        }

        driver.setAlert(false)

        #expect(!driver.showAlert)
        #expect(driver.alertKind == nil)
        #expect(driver.alertTitle.isEmpty)
        #expect(driver.alertMessage.isEmpty)
    }
}

private enum LoginAlertKind: Equatable {
    case emailUnavailable
    case error
}

@MainActor
private struct LoginTestDriver {
    private let feature: StoreOf<LoginFeature>

    var isLoading: Bool {
        feature.state.isLoading
    }

    var showAlert: Bool {
        feature.state.showAlert
    }

    var alertKind: LoginAlertKind? {
        switch feature.state.alertType {
        case .emailUnavailable:
            return .emailUnavailable
        case .error:
            return .error
        case .none:
            return nil
        }
    }

    var alertTitle: String {
        feature.state.alertTitle
    }

    var alertMessage: String {
        feature.state.alertMessage
    }

    init(useCase: SignInUseCase) {
        feature = ComposableArchitecture.Store(
            initialState: LoginFeature.State()
        ) {
            LoginFeature()
        } withDependencies: {
            $0.signInUseCase = .live(useCase)
        }
    }

    func tapSignInButton(_ provider: AuthProvider) {
        feature.send(.tapSignInButton(provider))
    }

    func setAlert(_ isPresented: Bool) {
        feature.send(.binding(.set(\.showAlert, isPresented)))
    }
}
