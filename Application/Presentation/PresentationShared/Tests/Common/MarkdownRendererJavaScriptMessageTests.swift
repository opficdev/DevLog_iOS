//
//  MarkdownRendererJavaScriptMessageTests.swift
//  PresentationSharedTests
//
//  Created by opfic on 7/25/26.
//

import Testing
@testable import PresentationShared

struct MarkdownRendererJavaScriptMessageTests {
    @Test("유한한 양수 높이만 변환한다")
    func 유한한_양수_높이만_변환한다() {
        let message = MarkdownRendererBridge.JavaScriptMessage(
            name: "contentHeight",
            body: ["height": 240.5]
        )

        #expect(message == .contentHeight(240.5))
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "contentHeight",
                body: ["height": 0]
            ) == nil
        )
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "contentHeight",
                body: ["height": -1]
            ) == nil
        )
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "contentHeight",
                body: ["height": Double.infinity]
            ) == nil
        )
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "contentHeight",
                body: ["height": true]
            ) == nil
        )
    }

    @Test("정수 Todo 번호만 변환한다")
    func 정수_Todo_번호만_변환한다() {
        let message = MarkdownRendererBridge.JavaScriptMessage(
            name: "todoReference",
            body: ["number": 42]
        )

        #expect(message == .todoReference(42))
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "todoReference",
                body: ["number": 4.2]
            ) == nil
        )
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "todoReference",
                body: ["number": true]
            ) == nil
        )
    }

    @Test("외부 링크 문자열만 변환한다")
    func 외부_링크_문자열만_변환한다() {
        let message = MarkdownRendererBridge.JavaScriptMessage(
            name: "externalLink",
            body: ["url": "https://example.com"]
        )

        #expect(message == .externalLink("https://example.com"))
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "externalLink",
                body: ["url": 1]
            ) == nil
        )
    }

    @Test("알 수 없는 이름과 잘못된 payload를 무시한다")
    func 알_수_없는_이름과_잘못된_payload를_무시한다() {
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "unknown",
                body: ["height": 100]
            ) == nil
        )
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "contentHeight",
                body: "invalid"
            ) == nil
        )
    }
}
