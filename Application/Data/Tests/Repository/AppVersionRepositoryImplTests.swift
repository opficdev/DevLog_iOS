//
//  AppVersionRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 7/22/26.
//

import Testing
@testable import Data

struct AppVersionRepositoryImplTests {
    @Test("필수 버전 조회는 구성 서비스의 값을 반환한다")
    func 필수_버전_조회는_구성_서비스의_값을_반환한다() async throws {
        let service = AppVersionConfigurationServiceSpy(result: .success("1.5"))
        let repository = AppVersionRepositoryImpl(service: service)

        #expect(try await repository.fetchRequiredVersion() == "1.5")
        #expect(await service.fetchCallCount() == 1)
    }

    @Test("필수 버전 조회는 구성 서비스의 오류를 그대로 반환한다")
    func 필수_버전_조회는_구성_서비스의_오류를_그대로_반환한다() async {
        let service = AppVersionConfigurationServiceSpy(
            result: .failure(AppVersionConfigurationServiceTestError.fetchFailed)
        )
        let repository = AppVersionRepositoryImpl(service: service)

        await #expect(throws: AppVersionConfigurationServiceTestError.fetchFailed) {
            try await repository.fetchRequiredVersion()
        }
    }
}

private actor AppVersionConfigurationServiceSpy: AppVersionConfigurationService {
    private let result: Result<String, Error>
    private var count = 0

    init(result: Result<String, Error>) {
        self.result = result
    }

    func fetchRequiredVersion() async throws -> String {
        count += 1
        return try result.get()
    }

    func fetchCallCount() -> Int {
        count
    }
}

private enum AppVersionConfigurationServiceTestError: Error {
    case fetchFailed
}
