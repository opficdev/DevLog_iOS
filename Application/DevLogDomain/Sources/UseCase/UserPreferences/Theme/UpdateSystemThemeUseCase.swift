//
//  UpdateSystemThemeUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/25/26.
//

import DevLogCore

public protocol UpdateSystemThemeUseCase {
    func execute(_ theme: SystemTheme)
}
