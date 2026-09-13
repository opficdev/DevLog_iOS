//
//  DevelopmentDependencyPreparation.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import Domain
import PresentationShared

public enum DevelopmentDependencyPreparation {
    public static func prepareGoal(
        _ dependencies: inout DependencyValues,
        fetchGoalUseCase: FetchDevelopmentGoalUseCase
    ) {
        dependencies.developmentFetchGoalUseCase = fetchGoalUseCase
    }

    public static func prepareQuery(
        _ dependencies: inout DependencyValues,
        fetchRecordsUseCase: FetchDevelopmentRecordsUseCase,
        fetchRecordHistoryUseCase: FetchDevelopmentRecordHistoryUseCase
    ) {
        dependencies.developmentFetchRecordsUseCase = fetchRecordsUseCase
        dependencies.developmentFetchRecordHistoryUseCase = fetchRecordHistoryUseCase
    }

    public static func prepareMutation(
        _ dependencies: inout DependencyValues,
        createRecordUseCase: CreateDevelopmentRecordUseCase,
        saveRecordDraftUseCase: SaveDevelopmentRecordDraftUseCase,
        confirmRecordUseCase: ConfirmDevelopmentRecordUseCase
    ) {
        dependencies.developmentCreateRecordUseCase = createRecordUseCase
        dependencies.developmentSaveRecordDraftUseCase = saveRecordDraftUseCase
        dependencies.developmentConfirmRecordUseCase = confirmRecordUseCase
    }
}

extension DependencyValues {
    var developmentFetchGoalUseCase: FetchDevelopmentGoalUseCase {
        get { self[DevelopmentFetchGoalUseCaseKey.self] }
        set { self[DevelopmentFetchGoalUseCaseKey.self] = newValue }
    }

    var developmentFetchRecordsUseCase: FetchDevelopmentRecordsUseCase {
        get { self[DevelopmentFetchRecordsUseCaseKey.self] }
        set { self[DevelopmentFetchRecordsUseCaseKey.self] = newValue }
    }

    var developmentFetchRecordHistoryUseCase: FetchDevelopmentRecordHistoryUseCase {
        get { self[DevelopmentFetchRecordHistoryUseCaseKey.self] }
        set { self[DevelopmentFetchRecordHistoryUseCaseKey.self] = newValue }
    }

    var developmentCreateRecordUseCase: CreateDevelopmentRecordUseCase {
        get { self[DevelopmentCreateRecordUseCaseKey.self] }
        set { self[DevelopmentCreateRecordUseCaseKey.self] = newValue }
    }

    var developmentSaveRecordDraftUseCase: SaveDevelopmentRecordDraftUseCase {
        get { self[DevelopmentSaveRecordDraftUseCaseKey.self] }
        set { self[DevelopmentSaveRecordDraftUseCaseKey.self] = newValue }
    }

    var developmentConfirmRecordUseCase: ConfirmDevelopmentRecordUseCase {
        get { self[DevelopmentConfirmRecordUseCaseKey.self] }
        set { self[DevelopmentConfirmRecordUseCaseKey.self] = newValue }
    }
}

private enum DevelopmentFetchGoalUseCaseKey: DependencyKey {
    static var liveValue: FetchDevelopmentGoalUseCase {
        preconditionFailure("FetchDevelopmentGoalUseCase must be provided.")
    }
}

private enum DevelopmentFetchRecordsUseCaseKey: DependencyKey {
    static var liveValue: FetchDevelopmentRecordsUseCase {
        preconditionFailure("FetchDevelopmentRecordsUseCase must be provided.")
    }
}

private enum DevelopmentFetchRecordHistoryUseCaseKey: DependencyKey {
    static var liveValue: FetchDevelopmentRecordHistoryUseCase {
        preconditionFailure("FetchDevelopmentRecordHistoryUseCase must be provided.")
    }
}

private enum DevelopmentCreateRecordUseCaseKey: DependencyKey {
    static var liveValue: CreateDevelopmentRecordUseCase {
        preconditionFailure("CreateDevelopmentRecordUseCase must be provided.")
    }
}

private enum DevelopmentSaveRecordDraftUseCaseKey: DependencyKey {
    static var liveValue: SaveDevelopmentRecordDraftUseCase {
        preconditionFailure("SaveDevelopmentRecordDraftUseCase must be provided.")
    }
}

private enum DevelopmentConfirmRecordUseCaseKey: DependencyKey {
    static var liveValue: ConfirmDevelopmentRecordUseCase {
        preconditionFailure("ConfirmDevelopmentRecordUseCase must be provided.")
    }
}
