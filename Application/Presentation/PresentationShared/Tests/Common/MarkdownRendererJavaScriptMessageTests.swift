//
//  MarkdownRendererJavaScriptMessageTests.swift
//  PresentationSharedTests
//
//  Created by opfic on 7/25/26.
//

import Testing
@testable import PresentationShared

struct MarkdownRendererJavaScriptMessageTests {
    @Test("renderer payload는 하단 문서 여백을 포함하지 않는다")
    func renderer_payload는_하단_문서_여백을_포함하지_않는다() {
        let payload = MarkdownRendererBridge.RenderPayload(
            markdown: "",
            references: [:],
            colorScheme: "light",
            fontSize: 17
        )

        #expect(payload.javaScriptValue["bottomContentInset"] == nil)
    }

    @Test("지원하지 않는 contentHeight 메시지를 무시한다")
    func 지원하지_않는_contentHeight_메시지를_무시한다() {
        #expect(
            MarkdownRendererBridge.JavaScriptMessage(
                name: "contentHeight",
                body: ["height": 240.5]
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
                name: "todoReference",
                body: "invalid"
            ) == nil
        )
    }
}
