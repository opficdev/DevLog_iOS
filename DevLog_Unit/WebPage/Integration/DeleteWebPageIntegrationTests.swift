//
//  DeleteWebPageIntegrationTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/6/26.
//

import Testing
import Foundation

@Suite(.serialized)
struct DeleteWebPageIntegrationTests {
    @Test("웹페이지 삭제를 되돌리면 목록에 보인다")
    func 웹페이지_삭제를_되돌리면_목록에_보인다() async throws {
        let authSession = try await LocalFirebaseRESTSupport.shared.anonymousSignIn()
        let seededWebPage = try await LocalFirebaseRESTSupport.shared.seedWebPage(
            userId: authSession.userId
        )

        try await LocalFirebaseRESTSupport.shared.requestWebPageDeletion(
            urlString: seededWebPage.urlString,
            idToken: authSession.idToken
        )

        try await LocalFirebaseRESTSupport.shared.waitUntil {
            let visibleWebPageURLs = try await LocalFirebaseRESTSupport.shared.fetchWebPageURLs(
                userId: authSession.userId
            )
            return !visibleWebPageURLs.contains(seededWebPage.urlString)
        }

        try await LocalFirebaseRESTSupport.shared.undoWebPageDeletion(
            urlString: seededWebPage.urlString,
            idToken: authSession.idToken
        )

        try await LocalFirebaseRESTSupport.shared.waitUntil {
            let visibleWebPageURLs = try await LocalFirebaseRESTSupport.shared.fetchWebPageURLs(
                userId: authSession.userId
            )
            return visibleWebPageURLs.contains(seededWebPage.urlString)
        }

        try await Task.sleep(for: .seconds(6))

        let visibleWebPageURLs = try await LocalFirebaseRESTSupport.shared.fetchWebPageURLs(
            userId: authSession.userId
        )
        #expect(visibleWebPageURLs.contains(seededWebPage.urlString))
    }
}
