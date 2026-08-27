//
//  CreateDevelopmentGoalUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

import Foundation

public final class CreateDevelopmentGoalUseCaseImpl: CreateDevelopmentGoalUseCase {
    private let repository: DevelopmentGoalRepository
    private let idProvider: () -> String

    init(
        _ repository: DevelopmentGoalRepository,
        idProvider: @escaping () -> String = { UUID().uuidString }
    ) {
        self.repository = repository
        self.idProvider = idProvider
    }

    public func execute(title: String, description: String) async throws -> DevelopmentGoal {
        try await repository.createGoal(
            id: idProvider(),
            title: title,
            description: description
        )
    }
}
