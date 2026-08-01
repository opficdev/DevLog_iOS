//
//  MarkdownRendererURLPolicyTests.swift
//  PresentationSharedTests
//
//  Created by opfic on 7/25/26.
//

import Foundation
import Testing
@testable import PresentationShared

struct MarkdownRendererURLPolicyTests {
    @Test(
        "허용된 외부 URL scheme만 반환한다",
        arguments: [
            "https://example.com/path",
            "http://example.com",
            "mailto:test@example.com"
        ]
    )
    func 허용된_외부_URL_scheme만_반환한다(value: String) {
        #expect(MarkdownRendererURLPolicy.externalURL(from: value) != nil)
    }

    @Test(
        "위험하거나 지원하지 않는 URL scheme을 차단한다",
        arguments: [
            "javascript:alert(1)",
            "file:///private/data",
            "example://reference/1",
            "https:example.com",
            "example.com"
        ]
    )
    func 위험하거나_지원하지_않는_URL_scheme을_차단한다(value: String) {
        #expect(MarkdownRendererURLPolicy.externalURL(from: value) == nil)
    }

    @Test("renderer 문서와 같은 file URL navigation만 허용한다")
    func renderer_문서와_같은_file_URL_navigation만_허용한다() throws {
        let indexURL = try #require(
            URL(string: "file:///bundle/MarkdownRenderer/index.html")
        )
        let fragmentURL = try #require(
            URL(string: "file:///bundle/MarkdownRenderer/index.html#section")
        )
        let otherFileURL = try #require(
            URL(string: "file:///bundle/MarkdownRenderer/other.html")
        )
        let remoteURL = try #require(
            URL(string: "https://example.com")
        )

        #expect(
            MarkdownRendererURLPolicy.allowsRendererNavigation(
                fragmentURL,
                indexURL: indexURL
            )
        )
        #expect(
            !MarkdownRendererURLPolicy.allowsRendererNavigation(
                otherFileURL,
                indexURL: indexURL
            )
        )
        #expect(
            !MarkdownRendererURLPolicy.allowsRendererNavigation(
                remoteURL,
                indexURL: indexURL
            )
        )
    }
}
