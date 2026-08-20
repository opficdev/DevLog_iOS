//
//  CollectionViewControllerSnapshotTests.swift
//  CollectionUITests
//
//  Created by opfic on 8/20/26.
//

import Testing
import UIKit
@testable import CollectionUI

@MainActor
struct CollectionViewControllerSnapshotTests {
    @Test("controller는 section과 item을 diffable snapshot으로 적용한다")
    func appliesRenderingSnapshot() {
        let controller = CollectionViewController(configuration: configuration(
            snapshot: .init(sections: [
                .init(identifier: "default", itemIdentifiers: ["todo-1", "todo-2"])
            ])
        ))

        let snapshot = controller.snapshot()

        #expect(snapshot.sectionIdentifiers == ["default"])
        #expect(snapshot.itemIdentifiers(inSection: "default") == ["todo-1", "todo-2"])
    }

    @Test("다시 구성할 item만 diffable snapshot에 표시한다")
    func reconfiguresSpecifiedItems() {
        let renderingSnapshot = CollectionRenderingSnapshot<String, String>(
            sections: [
                .init(identifier: "default", itemIdentifiers: ["todo-1", "todo-2"])
            ],
            reconfiguredItemIdentifiers: ["todo-2"]
        )
        let controller = CollectionViewController(configuration: configuration(snapshot: renderingSnapshot))

        #expect(controller.makeDiffableSnapshot(from: renderingSnapshot).reconfiguredItemIdentifiers == ["todo-2"])
    }

    private func configuration(
        snapshot: CollectionRenderingSnapshot<String, String>
    ) -> CollectionViewConfiguration<String, String> {
        CollectionViewConfiguration(
            snapshot: snapshot,
            layoutProvider: { _, _ in
                NSCollectionLayoutSection(group: .horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(44)
                    ),
                    subitems: []
                ))
            },
            cellProvider: { collectionView, indexPath, _ in
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: "cell",
                    for: indexPath
                )
            }
        )
    }
}
