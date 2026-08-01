//
//  MarkdownRendererBundleTests.swift
//  MarkdownRendererTests
//
//  Created by opfic on 8/1/26.
//

import Foundation
import Testing
@testable import MarkdownRenderer

struct MarkdownRendererBundleTests {
    @Test("module bundle에서 renderer index 자원을 찾는다")
    func module_bundle에서_renderer_index_자원을_찾는다() throws {
        let url = try #require(MarkdownRendererBundle.indexURL)

        #expect(url.lastPathComponent == "index.html")
        #expect(url.deletingLastPathComponent() == MarkdownRendererBundle.bundle.bundleURL)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }
}
