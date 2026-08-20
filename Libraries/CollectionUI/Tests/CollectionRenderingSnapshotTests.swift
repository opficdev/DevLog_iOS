//
//  CollectionRenderingSnapshotTests.swift
//  CollectionUITests
//
//  Created by opfic on 8/20/26.
//

import Testing
@testable import CollectionUI

struct CollectionRenderingSnapshotTests {
    @Test("section과 item 식별자의 표시 순서를 유지한다")
    func preservesSectionAndItemIdentifierOrder() {
        let snapshot = CollectionRenderingSnapshot<String, String>(
            sections: [
                .init(identifier: "pinned", itemIdentifiers: ["todo-1", "todo-2"]),
                .init(identifier: "default", itemIdentifiers: ["todo-3"])
            ]
        )

        #expect(snapshot.sections.map(\.identifier) == ["pinned", "default"])
        #expect(snapshot.sections[0].itemIdentifiers == ["todo-1", "todo-2"])
        #expect(snapshot.sections[1].itemIdentifiers == ["todo-3"])
    }

    @Test("내용이 변경된 item 식별자를 별도로 보관한다")
    func storesReconfiguredItemIdentifiers() {
        let snapshot = CollectionRenderingSnapshot<String, String>(
            sections: [
                .init(identifier: "default", itemIdentifiers: ["todo-1", "todo-2"])
            ],
            reconfiguredItemIdentifiers: ["todo-2"]
        )

        #expect(snapshot.reconfiguredItemIdentifiers == ["todo-2"])
    }

    @Test("동일한 rendering snapshot은 같은 값으로 비교한다")
    func comparesEqualRenderingSnapshots() {
        let section = CollectionRenderingSnapshot<String, String>.Section(
            identifier: "default",
            itemIdentifiers: ["todo-1"]
        )
        let lhs = CollectionRenderingSnapshot<String, String>(sections: [section])
        let rhs = CollectionRenderingSnapshot<String, String>(sections: [section])

        #expect(lhs == rhs)
    }
}
