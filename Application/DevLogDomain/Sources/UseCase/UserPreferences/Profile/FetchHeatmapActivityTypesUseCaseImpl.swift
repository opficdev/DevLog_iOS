//
//  FetchHeatmapActivityTypesUseCaseImpl.swift
//  DevLogDomain
//
//  Created by 최윤진 on 3/2/26.
//

public final class FetchHeatmapActivityTypesUseCaseImpl: FetchHeatmapActivityTypesUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    public func execute() -> [String] {
        repository.heatmapActivityTypes()
    }
}
