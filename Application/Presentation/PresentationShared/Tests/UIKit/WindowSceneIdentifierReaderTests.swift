//
//  WindowSceneIdentifierReaderTests.swift
//  PresentationSharedTests
//
//  Created by opfic on 7/27/26.
//

import Testing
@testable import PresentationShared

struct WindowSceneIdentifierReaderTests {
    @Test("Coordinator는 scene identifier가 변경될 때만 갱신한다")
    func Coordinator는_scene_identifier가_변경될_때만_갱신한다() {
        let coordinator = WindowSceneIdentifierReader.Coordinator()

        #expect(coordinator.update(identifier: nil) == false)
        #expect(coordinator.update(identifier: "scene-a"))
        #expect(coordinator.update(identifier: "scene-a") == false)
        #expect(coordinator.update(identifier: "scene-b"))
        #expect(coordinator.update(identifier: nil))
    }
}
