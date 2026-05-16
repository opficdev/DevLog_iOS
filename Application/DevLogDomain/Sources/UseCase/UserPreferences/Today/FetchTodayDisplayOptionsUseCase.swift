//
//  FetchTodayDisplayOptionsUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/6/26.
//

import DevLogCore

public protocol FetchTodayDisplayOptionsUseCase {
    func execute() -> TodayDisplayOptions
}
