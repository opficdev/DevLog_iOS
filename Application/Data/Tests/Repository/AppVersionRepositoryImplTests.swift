//
//  AppVersionRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 7/22/26.
//

import Testing
@testable import Data

struct AppVersionRepositoryImplTests {
    @Test("최신 버전 조회는 App Store 서비스의 값을 반환한다")
    func 최신_버전_조회는_App_Store_서비스의_값을_반환한다() async throws {
        let service = AppStoreVersionServiceSpy(result: .success("1.5"))
        let repository = AppVersionRepositoryImpl(service: service)

        #expect(try await repository.fetchLatestVersion() == "1.5")
        #expect(await service.fetchCallCount() == 1)
    }

    @Test("최신 버전 조회는 App Store 서비스의 오류를 그대로 반환한다")
    func 최신_버전_조회는_App_Store_서비스의_오류를_그대로_반환한다() async {
        let service = AppStoreVersionServiceSpy(
            result: .failure(AppStoreVersionServiceTestError.fetchFailed)
        )
        let repository = AppVersionRepositoryImpl(service: service)

        await #expect(throws: AppStoreVersionServiceTestError.fetchFailed) {
            try await repository.fetchLatestVersion()
        }
    }
}

private actor AppStoreVersionServiceSpy: AppStoreVersionService {
    private let result: Result<String, Error>
    private var count = 0

    init(result: Result<String, Error>) {
        self.result = result
    }

    func fetchLatestVersion() async throws -> String {
        count += 1
        return try result.get()
    }

    func fetchCallCount() -> Int {
        count
    }
}

private enum AppStoreVersionServiceTestError: Error {
    case fetchFailed
}
