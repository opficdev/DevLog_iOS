//
//  AppStoreVersionService.swift
//  Data
//
//  Created by opfic on 7/22/26.
//

public protocol AppStoreVersionService {
    func fetchLatestVersion() async throws -> String
}
