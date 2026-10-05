//
//  DevelopmentGoalListFeature+Dependencies.swift
//  DevelopmentTab
//
//  Created by opfic on 10/5/26.
//

import Domain
import PresentationShared

extension DependencyValues {
    var developmentTabFetchGoalsUseCase: FetchDevelopmentGoalsUseCase {
        get { self[FetchDevelopmentGoalsUseCaseKey.self] }
        set { self[FetchDevelopmentGoalsUseCaseKey.self] = newValue }
    }

    var developmentTabFetchRecentRecordUseCase: FetchRecentDevelopmentRecordUseCase {
        get { self[FetchRecentDevelopmentRecordUseCaseKey.self] }
        set { self[FetchRecentDevelopmentRecordUseCaseKey.self] = newValue }
    }
}

private enum FetchDevelopmentGoalsUseCaseKey: DependencyKey {
    static var liveValue: FetchDevelopmentGoalsUseCase {
        preconditionFailure("FetchDevelopmentGoalsUseCase must be provided.")
    }
}

private enum FetchRecentDevelopmentRecordUseCaseKey: DependencyKey {
    static var liveValue: FetchRecentDevelopmentRecordUseCase {
        preconditionFailure("FetchRecentDevelopmentRecordUseCase must be provided.")
    }
}
