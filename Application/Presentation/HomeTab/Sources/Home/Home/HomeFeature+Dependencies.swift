//
//  HomeFeature+Dependencies.swift
//  HomeTab
//
//  Created by opfic on 6/14/26.
//

import PresentationShared
import Domain

extension DependencyValues {
    var homeUpdateTodoCategoryPreferencesUseCase: UpdateTodoCategoryPreferencesUseCase {
        get { self[HomeUpdatePreferencesUseCaseKey.self] }
        set { self[HomeUpdatePreferencesUseCaseKey.self] = newValue }
    }

    var homeAddWebPageUseCase: AddWebPageUseCase {
        get { self[HomeAddWebPageUseCaseKey.self] }
        set { self[HomeAddWebPageUseCaseKey.self] = newValue }
    }

    var homeDeleteWebPageUseCase: DeleteWebPageUseCase {
        get { self[HomeDeleteWebPageUseCaseKey.self] }
        set { self[HomeDeleteWebPageUseCaseKey.self] = newValue }
    }

    var homeUndoDeleteWebPageUseCase: UndoDeleteWebPageUseCase {
        get { self[HomeUndoDeleteWebPageUseCaseKey.self] }
        set { self[HomeUndoDeleteWebPageUseCaseKey.self] = newValue }
    }

    var homeFetchTodosUseCase: FetchTodosUseCase {
        get { self[HomeFetchTodosUseCaseKey.self] }
        set { self[HomeFetchTodosUseCaseKey.self] = newValue }
    }

    var homeFetchWebPagesUseCase: FetchWebPagesUseCase {
        get { self[HomeFetchWebPagesUseCaseKey.self] }
        set { self[HomeFetchWebPagesUseCaseKey.self] = newValue }
    }

    var homeNetworkConnectivityUseCase: ObserveNetworkConnectivityUseCase {
        get { self[HomeNetworkConnectivityUseCaseKey.self] }
        set { self[HomeNetworkConnectivityUseCaseKey.self] = newValue }
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

private enum HomeAddWebPageUseCaseKey: DependencyKey {
    static var liveValue: AddWebPageUseCase {
        preconditionFailure("AddWebPageUseCase must be provided.")
    }

    static var testValue: AddWebPageUseCase {
        liveValue
    }
}

private enum HomeDeleteWebPageUseCaseKey: DependencyKey {
    static var liveValue: DeleteWebPageUseCase {
        preconditionFailure("DeleteWebPageUseCase must be provided.")
    }

    static var testValue: DeleteWebPageUseCase {
        liveValue
    }
}

private enum HomeUndoDeleteWebPageUseCaseKey: DependencyKey {
    static var liveValue: UndoDeleteWebPageUseCase {
        preconditionFailure("UndoDeleteWebPageUseCase must be provided.")
    }

    static var testValue: UndoDeleteWebPageUseCase {
        liveValue
    }
}

private enum HomeFetchTodosUseCaseKey: DependencyKey {
    static var liveValue: FetchTodosUseCase {
        preconditionFailure("FetchTodosUseCase must be provided.")
    }

    static var testValue: FetchTodosUseCase {
        liveValue
    }
}

private enum HomeFetchWebPagesUseCaseKey: DependencyKey {
    static var liveValue: FetchWebPagesUseCase {
        preconditionFailure("FetchWebPagesUseCase must be provided.")
    }

    static var testValue: FetchWebPagesUseCase {
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
