//
//  DevelopmentTabDependencyPreparation.swift
//  DevelopmentTab
//
//  Created by opfic on 10/5/26.
//

import Domain
import PresentationShared

public enum DevelopmentTabDependencyPreparation {
    public static func prepare(
        _ dependencies: inout DependencyValues,
        goalsUseCase: FetchDevelopmentGoalsUseCase,
        recentRecordUseCase: FetchRecentDevelopmentRecordUseCase
    ) {
        dependencies.developmentTabFetchGoalsUseCase = goalsUseCase
        dependencies.developmentTabFetchRecentRecordUseCase = recentRecordUseCase
    }
}
