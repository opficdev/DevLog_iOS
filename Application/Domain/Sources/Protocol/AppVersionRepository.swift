//
//  AppVersionRepository.swift
//  Domain
//
//  Created by opfic on 7/22/26.
//

public protocol AppVersionRepository {
    func fetchRequiredVersion() async throws -> String
}
