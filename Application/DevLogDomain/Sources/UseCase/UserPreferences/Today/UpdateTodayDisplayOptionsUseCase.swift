//
//  UpdateTodayDisplayOptionsUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/6/26.
//

import DevLogCore

public protocol UpdateTodayDisplayOptionsUseCase {
    func execute(_ options: TodayDisplayOptions)
}
