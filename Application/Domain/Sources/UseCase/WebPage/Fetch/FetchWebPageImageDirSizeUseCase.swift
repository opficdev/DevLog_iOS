//
//  FetchWebPageImageDirSizeUseCase.swift
//  Domain
//
//  Created by opfic on 4/14/26.
//

public protocol FetchWebPageImageDirSizeUseCase {
    func execute() async -> Int64
}
