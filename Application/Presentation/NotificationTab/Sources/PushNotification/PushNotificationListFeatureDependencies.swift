//
//  PushNotificationListFeatureDependencies.swift
//  Presentation
//
//  Created by opfic on 6/12/26.
//

import PresentationShared
import Domain

extension DependencyValues {
    var fetchPushNotificationsUseCase: FetchPushNotificationsUseCase {
        get { self[FetchPushNotificationsUseCaseKey.self] }
        set { self[FetchPushNotificationsUseCaseKey.self] = newValue }
    }

    var deletePushNotificationUseCase: DeletePushNotificationUseCase {
        get { self[DeletePushNotificationUseCaseKey.self] }
        set { self[DeletePushNotificationUseCaseKey.self] = newValue }
    }

    var undoDeletePushNotificationUseCase: UndoDeletePushNotificationUseCase {
        get { self[UndoDeletePushNotificationUseCaseKey.self] }
        set { self[UndoDeletePushNotificationUseCaseKey.self] = newValue }
    }

    var togglePushNotificationReadUseCase: TogglePushNotificationReadUseCase {
        get { self[TogglePushNotificationReadUseCaseKey.self] }
        set { self[TogglePushNotificationReadUseCaseKey.self] = newValue }
    }

    var updatePushNotificationQueryUseCase: UpdatePushNotificationQueryUseCase {
        get { self[UpdatePushNotificationQueryUseCaseKey.self] }
        set { self[UpdatePushNotificationQueryUseCaseKey.self] = newValue }
    }
}

private enum FetchPushNotificationsUseCaseKey: DependencyKey {
    static var liveValue: FetchPushNotificationsUseCase {
        preconditionFailure("FetchPushNotificationsUseCase must be provided.")
    }

    static var testValue: FetchPushNotificationsUseCase {
        liveValue
    }
}

private enum DeletePushNotificationUseCaseKey: DependencyKey {
    static var liveValue: DeletePushNotificationUseCase {
        preconditionFailure("DeletePushNotificationUseCase must be provided.")
    }

    static var testValue: DeletePushNotificationUseCase {
        liveValue
    }
}

private enum UndoDeletePushNotificationUseCaseKey: DependencyKey {
    static var liveValue: UndoDeletePushNotificationUseCase {
        preconditionFailure("UndoDeletePushNotificationUseCase must be provided.")
    }

    static var testValue: UndoDeletePushNotificationUseCase {
        liveValue
    }
}

private enum TogglePushNotificationReadUseCaseKey: DependencyKey {
    static var liveValue: TogglePushNotificationReadUseCase {
        preconditionFailure("TogglePushNotificationReadUseCase must be provided.")
    }

    static var testValue: TogglePushNotificationReadUseCase {
        liveValue
    }
}

private enum UpdatePushNotificationQueryUseCaseKey: DependencyKey {
    static var liveValue: UpdatePushNotificationQueryUseCase {
        preconditionFailure("UpdatePushNotificationQueryUseCase must be provided.")
    }

    static var testValue: UpdatePushNotificationQueryUseCase {
        liveValue
    }
}
