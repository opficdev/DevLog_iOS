//
//  UpdateProfileHeatmapActivityTypesUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 3/2/26.
//

final class UpdateProfileHeatmapActivityTypesUseCaseImpl: UpdateProfileHeatmapActivityTypesUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    func execute(_ activityTypes: [String]) {
        repository.setProfileHeatmapActivityTypes(activityTypes)
    }
}
