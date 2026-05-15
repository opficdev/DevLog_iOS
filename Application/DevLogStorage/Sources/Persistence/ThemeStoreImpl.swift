//
//  ThemeStoreImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Combine
import DevLogDomain
import DevLogDataCommon
import DevLogDataProtocol
import DevLogWidgetCore
import DevLogWidgetShared

final class ThemeStoreImpl: ThemeStore {
    private let subject = CurrentValueSubject<SystemTheme, Never>(.automatic)

    func observeTheme() -> AnyPublisher<SystemTheme, Never> {
        subject.eraseToAnyPublisher()
    }

    func send(_ theme: SystemTheme) {
        subject.send(theme)
    }
}
