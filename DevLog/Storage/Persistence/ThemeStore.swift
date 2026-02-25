//
//  ThemeStore.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Combine

final class ThemeStore {
    private let subject = CurrentValueSubject<SystemTheme, Never>(.automatic)

    var themePublisher: AnyPublisher<SystemTheme, Never> {
        subject.eraseToAnyPublisher()
    }

    func send(_ theme: SystemTheme) {
        subject.send(theme)
    }
}
