//
//  CheckAppUpdateUseCaseImplTests.swift
//  DomainTests
//
//  Created by opfic on 7/22/26.
//

import Testing
@testable import Domain

struct CheckAppUpdateUseCaseImplTests {
    @Test(
        "현재 마케팅 버전과 빌드 번호를 필수 버전과 비교한다",
        arguments: [
            ("1.4", "9", "1.5.1", true),
            ("1.5", "127", "1.5.128", true),
            ("1.5", "128", "1.5.128", false),
            ("1.5", "129", "1.5.128", false),
            ("1.9", "9", "1.10.1", true),
            ("1.5", "1", "1.5.0", false)
        ]
    )
    func 현재_마케팅_버전과_빌드_번호를_필수_버전과_비교한다(
        marketingVersion: String,
        buildNumber: String,
        requiredVersion: String,
        expectedResult: Bool
    ) async throws {
        let repository = AppVersionRepositorySpy(result: .success(requiredVersion))
        let useCase = CheckAppUpdateUseCaseImpl(repository)
        let currentVersion = try AppVersion(
            marketingVersion: marketingVersion,
            buildNumber: buildNumber
        )

        #expect(try await useCase.execute(currentVersion) == expectedResult)
        #expect(await repository.fetchCallCount() == 1)
    }

    @Test("필수 버전 형식이 잘못되면 invalidData 오류를 반환한다")
    func 필수_버전_형식이_잘못되면_invalidData_오류를_반환한다() async throws {
        let repository = AppVersionRepositorySpy(result: .success("latest"))
        let useCase = CheckAppUpdateUseCaseImpl(repository)
        let currentVersion = try AppVersion(marketingVersion: "1.5", buildNumber: "127")

        await #expect(throws: DomainLayerError.self) {
            try await useCase.execute(currentVersion)
        }
    }

    @Test("필수 버전 조회 오류를 그대로 반환한다")
    func 필수_버전_조회_오류를_그대로_반환한다() async throws {
        let repository = AppVersionRepositorySpy(
            result: .failure(AppVersionRepositoryTestError.fetchFailed)
        )
        let useCase = CheckAppUpdateUseCaseImpl(repository)
        let currentVersion = try AppVersion(marketingVersion: "1.5", buildNumber: "127")

        await #expect(throws: AppVersionRepositoryTestError.fetchFailed) {
            try await useCase.execute(currentVersion)
        }
    }
}

private actor AppVersionRepositorySpy: AppVersionRepository {
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

private enum AppVersionRepositoryTestError: Error {
    case fetchFailed
}
