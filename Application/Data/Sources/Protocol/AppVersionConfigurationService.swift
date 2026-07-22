//
//  AppVersionConfigurationService.swift
//  Data
//
//  Created by opfic on 7/22/26.
//

public protocol AppVersionConfigurationService {
    func fetchRequiredVersion() async throws -> String
}
