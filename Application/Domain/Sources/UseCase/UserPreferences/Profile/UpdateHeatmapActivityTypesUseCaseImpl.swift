//
//  UpdateHeatmapActivityTypesUseCaseImpl.swift
//  Domain
//
//  Created by 최윤진 on 3/2/26.
//

public final class UpdateHeatmapActivityTypesUseCaseImpl: UpdateHeatmapActivityTypesUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    public func execute(_ activityTypes: [String]) {
        repository.setHeatmapActivityTypes(activityTypes)
    }
}
