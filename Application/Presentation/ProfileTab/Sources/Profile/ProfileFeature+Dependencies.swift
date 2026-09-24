//
//  ProfileFeature+Dependencies.swift
//  ProfileTab
//
//  Created by opfic on 6/15/26.
//

import PresentationShared
import Domain

extension DependencyValues {
    var profileFetchDevelopmentGoalsUseCase: FetchDevelopmentGoalsUseCase {
        get { self[FetchDevelopmentGoalsKey.self] }
        set { self[FetchDevelopmentGoalsKey.self] = newValue }
    }

    var profileFetchUserDataUseCase: FetchUserDataUseCase {
        get { self[FetchUserDataKey.self] }
        set { self[FetchUserDataKey.self] = newValue }
    }

    var profileFetchImageDataUseCase: FetchProfileImageDataUseCase {
        get { self[FetchImageDataKey.self] }
        set { self[FetchImageDataKey.self] = newValue }
    }

    var profileFetchTodosUseCase: FetchTodosUseCase {
        get { self[FetchTodosKey.self] }
        set { self[FetchTodosKey.self] = newValue }
    }

    var profileTodoMutationEventBus: TodoMutationEventBus {
        get { self[TodoMutationEventBusKey.self] }
        set { self[TodoMutationEventBusKey.self] = newValue }
    }

    var profileUpsertStatusMessageUseCase: UpsertStatusMessageUseCase {
        get { self[UpsertStatusMessageKey.self] }
        set { self[UpsertStatusMessageKey.self] = newValue }
    }

    var profileFetchHeatmapActivityTypesUseCase: FetchHeatmapActivityTypesUseCase {
        get { self[FetchHeatmapTypesKey.self] }
        set { self[FetchHeatmapTypesKey.self] = newValue }
    }

    var profileUpdateHeatmapActivityTypesUseCase: UpdateHeatmapActivityTypesUseCase {
        get { self[UpdateHeatmapTypesKey.self] }
        set { self[UpdateHeatmapTypesKey.self] = newValue }
    }
}

private enum FetchDevelopmentGoalsKey: DependencyKey {
    static var liveValue: FetchDevelopmentGoalsUseCase {
        preconditionFailure("FetchDevelopmentGoalsUseCase must be provided.")
    }
}

private enum FetchUserDataKey: DependencyKey {
    static var liveValue: FetchUserDataUseCase {
        preconditionFailure("FetchUserDataUseCase must be provided.")
    }

    static var testValue: FetchUserDataUseCase {
        liveValue
    }
}

private enum FetchImageDataKey: DependencyKey {
    static var liveValue: FetchProfileImageDataUseCase {
        preconditionFailure("FetchProfileImageDataUseCase must be provided.")
    }

    static var testValue: FetchProfileImageDataUseCase {
        liveValue
    }
}

private enum FetchTodosKey: DependencyKey {
    static var liveValue: FetchTodosUseCase {
        preconditionFailure("FetchTodosUseCase must be provided.")
    }

    static var testValue: FetchTodosUseCase {
        liveValue
    }
}

private enum TodoMutationEventBusKey: DependencyKey {
    static var liveValue: TodoMutationEventBus {
        preconditionFailure("TodoMutationEventBus must be provided.")
    }
}

private enum UpsertStatusMessageKey: DependencyKey {
    static var liveValue: UpsertStatusMessageUseCase {
        preconditionFailure("UpsertStatusMessageUseCase must be provided.")
    }

    static var testValue: UpsertStatusMessageUseCase {
        liveValue
    }
}

private enum FetchHeatmapTypesKey: DependencyKey {
    static var liveValue: FetchHeatmapActivityTypesUseCase {
        preconditionFailure("FetchHeatmapActivityTypesUseCase must be provided.")
    }

    static var testValue: FetchHeatmapActivityTypesUseCase {
        liveValue
    }
}

private enum UpdateHeatmapTypesKey: DependencyKey {
    static var liveValue: UpdateHeatmapActivityTypesUseCase {
        preconditionFailure("UpdateHeatmapActivityTypesUseCase must be provided.")
    }

    static var testValue: UpdateHeatmapActivityTypesUseCase {
        liveValue
    }
}
