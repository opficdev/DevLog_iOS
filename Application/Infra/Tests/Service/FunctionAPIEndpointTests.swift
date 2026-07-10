//
//  FunctionAPIEndpointTests.swift
//  InfraTests
//
//  Created by opfic on 7/10/26.
//

import Testing
@testable import Infra

struct FunctionAPIEndpointTests {
    @Test("GitHub provider 연결 endpoint는 인증 link 경로를 사용한다")
    func 깃허브_provider_연결_endpoint는_인증_link_경로를_사용한다() {
        let endpoint = FunctionAPIEndpoint<FunctionAPIResponse>.linkGithubProvider

        #expect(endpoint.method.rawValue == "POST")
        #expect(endpoint.path == "/auth/github/link")
    }
}
