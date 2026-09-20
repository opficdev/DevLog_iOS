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
        createGoalUseCase: CreateDevelopmentGoalUseCase,
        fetchGoalUseCase: FetchDevelopmentGoalUseCase,
        updateGoalStatusUseCase: UpdateDevelopmentGoalStatusUseCase
    ) {
        dependencies.developmentCreateGoalUseCase = createGoalUseCase
        dependencies.developmentFetchGoalUseCase = fetchGoalUseCase
        dependencies.developmentUpdateGoalStatusUseCase = updateGoalStatusUseCase
    }

    public static func prepareQuery(
        _ dependencies: inout DependencyValues,
        fetchRecordsUseCase: FetchDevelopmentRecordsUseCase,
        fetchRecordHistoryUseCase: FetchDevelopmentRecordHistoryUseCase,
        fetchRecordVersionUseCase: FetchDevelopmentRecordVersionUseCase
    ) {
        dependencies.developmentFetchRecordsUseCase = fetchRecordsUseCase
        dependencies.developmentFetchRecordHistoryUseCase = fetchRecordHistoryUseCase
        dependencies.developmentFetchRecordVersionUseCase = fetchRecordVersionUseCase
    }

    public static func prepareMutation(
        _ dependencies: inout DependencyValues,
        createRecordUseCase: CreateDevelopmentRecordUseCase,
        saveRecordDraftUseCase: SaveDevelopmentRecordDraftUseCase,
        confirmRecordUseCase: ConfirmDevelopmentRecordUseCase,
        restoreRecordUseCase: RestoreDevelopmentRecordUseCase
    ) {
        dependencies.developmentCreateRecordUseCase = createRecordUseCase
        dependencies.developmentSaveRecordDraftUseCase = saveRecordDraftUseCase
        dependencies.developmentConfirmRecordUseCase = confirmRecordUseCase
        dependencies.developmentRestoreRecordUseCase = restoreRecordUseCase
    }

    public static func prepareTodo(
        _ dependencies: inout DependencyValues,
        fetchTodosUseCase: FetchTodosUseCase,
        updateTodoGoalUseCase: UpdateTodoGoalUseCase
    ) {
        dependencies.developmentFetchTodosUseCase = fetchTodosUseCase
        dependencies.developmentUpdateTodoGoalUseCase = updateTodoGoalUseCase
    }
}

extension DependencyValues {
    var developmentCreateGoalUseCase: CreateDevelopmentGoalUseCase {
        get { self[DevelopmentCreateGoalUseCaseKey.self] }
        set { self[DevelopmentCreateGoalUseCaseKey.self] = newValue }
    }

    var developmentFetchGoalUseCase: FetchDevelopmentGoalUseCase {
        get { self[DevelopmentFetchGoalUseCaseKey.self] }
        set { self[DevelopmentFetchGoalUseCaseKey.self] = newValue }
    }

    var developmentFetchRecordsUseCase: FetchDevelopmentRecordsUseCase {
        get { self[DevelopmentFetchRecordsUseCaseKey.self] }
        set { self[DevelopmentFetchRecordsUseCaseKey.self] = newValue }
    }

    var developmentUpdateGoalStatusUseCase: UpdateDevelopmentGoalStatusUseCase {
        get { self[DevelopmentUpdateGoalStatusUseCaseKey.self] }
        set { self[DevelopmentUpdateGoalStatusUseCaseKey.self] = newValue }
    }

    var developmentFetchRecordHistoryUseCase: FetchDevelopmentRecordHistoryUseCase {
        get { self[DevelopmentFetchRecordHistoryUseCaseKey.self] }
        set { self[DevelopmentFetchRecordHistoryUseCaseKey.self] = newValue }
    }

    var developmentFetchRecordVersionUseCase: FetchDevelopmentRecordVersionUseCase {
        get { self[DevelopmentFetchRecordVersionUseCaseKey.self] }
        set { self[DevelopmentFetchRecordVersionUseCaseKey.self] = newValue }
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

    var developmentRestoreRecordUseCase: RestoreDevelopmentRecordUseCase {
        get { self[DevelopmentRestoreRecordUseCaseKey.self] }
        set { self[DevelopmentRestoreRecordUseCaseKey.self] = newValue }
    }

    var developmentFetchTodosUseCase: FetchTodosUseCase {
        get { self[DevelopmentFetchTodosUseCaseKey.self] }
        set { self[DevelopmentFetchTodosUseCaseKey.self] = newValue }
    }

    var developmentUpdateTodoGoalUseCase: UpdateTodoGoalUseCase {
        get { self[DevelopmentUpdateTodoGoalUseCaseKey.self] }
        set { self[DevelopmentUpdateTodoGoalUseCaseKey.self] = newValue }
    }
}

private enum DevelopmentCreateGoalUseCaseKey: DependencyKey {
    static var liveValue: CreateDevelopmentGoalUseCase {
        preconditionFailure("CreateDevelopmentGoalUseCase must be provided.")
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

private enum DevelopmentUpdateGoalStatusUseCaseKey: DependencyKey {
    static var liveValue: UpdateDevelopmentGoalStatusUseCase {
        preconditionFailure("UpdateDevelopmentGoalStatusUseCase must be provided.")
    }
}

private enum DevelopmentFetchRecordHistoryUseCaseKey: DependencyKey {
    static var liveValue: FetchDevelopmentRecordHistoryUseCase {
        preconditionFailure("FetchDevelopmentRecordHistoryUseCase must be provided.")
    }
}

private enum DevelopmentFetchRecordVersionUseCaseKey: DependencyKey {
    static var liveValue: FetchDevelopmentRecordVersionUseCase {
        preconditionFailure("FetchDevelopmentRecordVersionUseCase must be provided.")
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

private enum DevelopmentRestoreRecordUseCaseKey: DependencyKey {
    static var liveValue: RestoreDevelopmentRecordUseCase {
        preconditionFailure("RestoreDevelopmentRecordUseCase must be provided.")
    }
}

private enum DevelopmentFetchTodosUseCaseKey: DependencyKey {
    static var liveValue: FetchTodosUseCase {
        preconditionFailure("FetchTodosUseCase must be provided.")
    }
}

private enum DevelopmentUpdateTodoGoalUseCaseKey: DependencyKey {
    static var liveValue: UpdateTodoGoalUseCase {
        preconditionFailure("UpdateTodoGoalUseCase must be provided.")
    }
}
