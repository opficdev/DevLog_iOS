//
//  CheckAppUpdateUseCaseImplTests.swift
//  DomainTests
//
//  Created by opfic on 7/22/26.
//

import Foundation
import Testing
@testable import Domain

struct CheckAppUpdateUseCaseImplTests {
    @Test("Bundle의 현재 버전보다 최신 버전이 높으면 업데이트가 필요하다")
    func Bundle의_현재_버전보다_최신_버전이_높으면_업데이트가_필요하다() async throws {
        let latestVersion = "\(try currentVersionValue()).1"
        let repository = AppVersionRepositorySpy(result: .success(latestVersion))
        let useCase = CheckAppUpdateUseCaseImpl(repository)

        #expect(try await useCase.execute())
        #expect(await repository.fetchCallCount() == 1)
    }

    @Test("Bundle의 현재 버전과 최신 버전이 같으면 업데이트가 필요하지 않다")
    func Bundle의_현재_버전과_최신_버전이_같으면_업데이트가_필요하지_않다() async throws {
        let repository = AppVersionRepositorySpy(result: .success(try currentVersionValue()))
        let useCase = CheckAppUpdateUseCaseImpl(repository)

        #expect(try await !useCase.execute())
        #expect(await repository.fetchCallCount() == 1)
    }

    @Test("최신 버전 형식이 잘못되면 invalidData 오류를 반환한다")
    func 최신_버전_형식이_잘못되면_invalidData_오류를_반환한다() async throws {
        let repository = AppVersionRepositorySpy(result: .success("latest"))
        let useCase = CheckAppUpdateUseCaseImpl(repository)
        await #expect(throws: DomainLayerError.self) {
            try await useCase.execute()
        }
    }

    @Test("최신 버전 조회 오류를 그대로 반환한다")
    func 최신_버전_조회_오류를_그대로_반환한다() async throws {
        let repository = AppVersionRepositorySpy(
            result: .failure(AppVersionRepositoryTestError.fetchFailed)
        )
        let useCase = CheckAppUpdateUseCaseImpl(repository)
        await #expect(throws: AppVersionRepositoryTestError.fetchFailed) {
            try await useCase.execute()
        }
    }
}

private func currentVersionValue() throws -> String {
    try #require(
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    )
}

private actor AppVersionRepositorySpy: AppVersionRepository {
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

private enum AppVersionRepositoryTestError: Error {
    case fetchFailed
}
