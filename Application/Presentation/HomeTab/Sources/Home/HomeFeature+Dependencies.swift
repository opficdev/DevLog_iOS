//
//  HomeFeature+Dependencies.swift
//  HomeTab
//
//  Created by opfic on 6/14/26.
//

import PresentationShared
import Domain

extension DependencyValues {
    var homeFetchDevelopmentGoalsUseCase: FetchDevelopmentGoalsUseCase {
        get { self[FetchDevelopmentGoalsUseCaseKey.self] }
        set { self[FetchDevelopmentGoalsUseCaseKey.self] = newValue }
    }

    var homeFetchRecentDevelopmentRecordUseCase: FetchRecentDevelopmentRecordUseCase {
        get { self[FetchRecentDevelopmentRecordUseCaseKey.self] }
        set { self[FetchRecentDevelopmentRecordUseCaseKey.self] = newValue }
    }

    var homeUpdateTodoCategoryPreferencesUseCase: UpdateTodoCategoryPreferencesUseCase {
        get { self[UpdatePreferencesUseCaseKey.self] }
        set { self[UpdatePreferencesUseCaseKey.self] = newValue }
    }

    var homeNetworkConnectivityUseCase: ObserveNetworkConnectivityUseCase {
        get { self[NetworkConnectivityUseCaseKey.self] }
        set { self[NetworkConnectivityUseCaseKey.self] = newValue }
    }
}

private enum FetchDevelopmentGoalsUseCaseKey: DependencyKey {
    static var liveValue: FetchDevelopmentGoalsUseCase {
        preconditionFailure("FetchDevelopmentGoalsUseCase must be provided.")
    }

    static var testValue: FetchDevelopmentGoalsUseCase {
        liveValue
    }
}

private enum FetchRecentDevelopmentRecordUseCaseKey: DependencyKey {
    static var liveValue: FetchRecentDevelopmentRecordUseCase {
        preconditionFailure("FetchRecentDevelopmentRecordUseCase must be provided.")
    }

    static var testValue: FetchRecentDevelopmentRecordUseCase {
        liveValue
    }
}

private enum UpdatePreferencesUseCaseKey: DependencyKey {
    static var liveValue: UpdateTodoCategoryPreferencesUseCase {
        preconditionFailure("UpdateTodoCategoryPreferencesUseCase must be provided.")
    }

    static var testValue: UpdateTodoCategoryPreferencesUseCase {
        liveValue
    }
}

private enum NetworkConnectivityUseCaseKey: DependencyKey {
    static var liveValue: ObserveNetworkConnectivityUseCase {
        preconditionFailure("ObserveNetworkConnectivityUseCase must be provided.")
    }

    static var testValue: ObserveNetworkConnectivityUseCase {
        liveValue
    }
}
