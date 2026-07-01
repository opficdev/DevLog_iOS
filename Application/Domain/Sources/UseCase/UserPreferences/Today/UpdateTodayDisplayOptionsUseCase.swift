//
//  UpdateTodayDisplayOptionsUseCase.swift
//  Domain
//
//  Created by opfic on 3/6/26.
//

import Core

public protocol UpdateTodayDisplayOptionsUseCase {
    func execute(_ options: TodayDisplayOptions)
}
