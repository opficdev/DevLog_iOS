//
//  FetchProfileHeatmapActivityTypesUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 3/2/26.
//

final class FetchProfileHeatmapActivityTypesUseCaseImpl: FetchProfileHeatmapActivityTypesUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    func execute() -> [String] {
        repository.profileHeatmapActivityTypes()
    }
}
