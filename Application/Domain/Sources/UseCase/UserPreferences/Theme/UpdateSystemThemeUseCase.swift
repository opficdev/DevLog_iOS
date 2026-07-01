//
//  UpdateSystemThemeUseCase.swift
//  Domain
//
//  Created by 최윤진 on 2/25/26.
//

import Core

public protocol UpdateSystemThemeUseCase {
    func execute(_ theme: SystemTheme)
}
