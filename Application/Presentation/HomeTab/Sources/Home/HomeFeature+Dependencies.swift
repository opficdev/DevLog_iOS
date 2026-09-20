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
        get { self[HomeFetchDevelopmentGoalsUseCaseKey.self] }
        set { self[HomeFetchDevelopmentGoalsUseCaseKey.self] = newValue }
    }

    var homeFetchDevelopmentRecordsUseCase: FetchDevelopmentRecordsUseCase {
        get { self[HomeFetchDevelopmentRecordsUseCaseKey.self] }
        set { self[HomeFetchDevelopmentRecordsUseCaseKey.self] = newValue }
    }

    var homeFetchDevelopmentRecordVersionUseCase: FetchDevelopmentRecordVersionUseCase {
        get { self[HomeFetchDevelopmentRecordVersionKey.self] }
        set { self[HomeFetchDevelopmentRecordVersionKey.self] = newValue }
    }

    var homeUpdateTodoCategoryPreferencesUseCase: UpdateTodoCategoryPreferencesUseCase {
        get { self[HomeUpdatePreferencesUseCaseKey.self] }
        set { self[HomeUpdatePreferencesUseCaseKey.self] = newValue }
    }

    var homeNetworkConnectivityUseCase: ObserveNetworkConnectivityUseCase {
        get { self[HomeNetworkConnectivityUseCaseKey.self] }
        set { self[HomeNetworkConnectivityUseCaseKey.self] = newValue }
    }
}

private enum HomeFetchDevelopmentGoalsUseCaseKey: DependencyKey {
    static var liveValue: FetchDevelopmentGoalsUseCase {
        preconditionFailure("FetchDevelopmentGoalsUseCase must be provided.")
    }

    static var testValue: FetchDevelopmentGoalsUseCase {
        liveValue
    }
}

private enum HomeFetchDevelopmentRecordsUseCaseKey: DependencyKey {
    static var liveValue: FetchDevelopmentRecordsUseCase {
        preconditionFailure("FetchDevelopmentRecordsUseCase must be provided.")
    }

    static var testValue: FetchDevelopmentRecordsUseCase {
        liveValue
    }
}

private enum HomeFetchDevelopmentRecordVersionKey: DependencyKey {
    static var liveValue: FetchDevelopmentRecordVersionUseCase {
        preconditionFailure("FetchDevelopmentRecordVersionUseCase must be provided.")
    }

    static var testValue: FetchDevelopmentRecordVersionUseCase {
        liveValue
    }
}

private enum HomeUpdatePreferencesUseCaseKey: DependencyKey {
    static var liveValue: UpdateTodoCategoryPreferencesUseCase {
        preconditionFailure("UpdateTodoCategoryPreferencesUseCase must be provided.")
    }

    static var testValue: UpdateTodoCategoryPreferencesUseCase {
        liveValue
    }
}

private enum HomeNetworkConnectivityUseCaseKey: DependencyKey {
    static var liveValue: ObserveNetworkConnectivityUseCase {
        preconditionFailure("ObserveNetworkConnectivityUseCase must be provided.")
    }

    static var testValue: ObserveNetworkConnectivityUseCase {
        liveValue
    }
}
