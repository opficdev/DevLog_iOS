//
//  FetchRecentSearchQueriesUseCase.swift
//  Domain
//
//  Created by 최윤진 on 2/25/26.
//

public protocol FetchRecentSearchQueriesUseCase {
    func execute() -> [String]
}
