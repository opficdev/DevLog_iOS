//
//  FunctionAPIEndpointTests.swift
//  InfraTests
//
//  Created by opfic on 7/3/26.
//

import Testing
@testable import Infra

struct FunctionAPIEndpointTests {
    @Test("WebPage 삭제 endpoint는 Firestore document id를 재인코딩하지 않는다")
    func WebPage_삭제_endpoint는_Firestore_document_id를_재인코딩하지_않는다() {
        let id = "https%3A%2F%2Fgithub%2Ecom%2Fopficdev"
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.requestWebPageDeletion(id)

        #expect(endpoint.path == "/web-pages/\(id)/deletion-request")
    }

    @Test("WebPage 삭제 복구 endpoint는 Firestore document id를 재인코딩하지 않는다")
    func WebPage_삭제_복구_endpoint는_Firestore_document_id를_재인코딩하지_않는다() {
        let id = "https%3A%2F%2Fgithub%2Ecom%2Fopficdev"
        let endpoint = FunctionAPIEndpoint<EmptyAPIResponse>.undoWebPageDeletion(id)

        #expect(endpoint.path == "/web-pages/\(id)/deletion-request")
    }
}
