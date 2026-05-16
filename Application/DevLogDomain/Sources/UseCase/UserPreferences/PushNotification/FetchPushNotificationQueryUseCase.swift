//
//  FetchPushNotificationQueryUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/25/26.
//

import DevLogCore

public protocol FetchPushNotificationQueryUseCase {
    func execute() -> PushNotificationQuery
}
