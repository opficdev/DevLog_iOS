//
//  CollectionViewControllerInteractionTests.swift
//  CollectionUITests
//
//  Created by opfic on 8/20/26.
//

import Testing
import UIKit
@testable import CollectionUI

@MainActor
struct CollectionViewControllerInteractionTests {
    @Test("선택과 표시 callback은 item 식별자를 전달한다")
    func forwardsSelectionAndDisplayIdentifiers() {
        var selectedIdentifier: String?
        var displayedIdentifier: String?
        let controller = controller(
            onSelect: { selectedIdentifier = $0 },
            onWillDisplay: { displayedIdentifier = $0 }
        )
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let indexPath = IndexPath(item: 0, section: 0)

        controller.collectionView(collectionView, didSelectItemAt: indexPath)
        controller.collectionView(collectionView, willDisplay: UICollectionViewCell(), forItemAt: indexPath)

        #expect(selectedIdentifier == "todo-1")
        #expect(displayedIdentifier == "todo-1")
    }

    @Test("prefetch와 취소 callback은 중복 item을 한 번만 전달한다")
    func deduplicatesPrefetchAndCancellationIdentifiers() {
        var prefetchedIdentifiers = [[String]]()
        var cancelledIdentifiers = [[String]]()
        let controller = controller(
            onPrefetch: { prefetchedIdentifiers.append($0) },
            onCancelPrefetch: { cancelledIdentifiers.append($0) }
        )
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let indexPath = IndexPath(item: 0, section: 0)

        controller.collectionView(collectionView, prefetchItemsAt: [indexPath, indexPath])
        controller.collectionView(collectionView, cancelPrefetchingForItemsAt: [indexPath, indexPath])

        #expect(prefetchedIdentifiers == [["todo-1"]])
        #expect(cancelledIdentifiers == [["todo-1"]])
    }

    private func controller(
        onSelect: ((String) -> Void)? = nil,
        onWillDisplay: ((String) -> Void)? = nil,
        onPrefetch: (([String]) -> Void)? = nil,
        onCancelPrefetch: (([String]) -> Void)? = nil
    ) -> CollectionViewController<String, String> {
        var configuration = CollectionViewConfiguration(
            snapshot: CollectionRenderingSnapshot(sections: [
                .init(identifier: "default", itemIdentifiers: ["todo-1"])
            ]),
            layoutProvider: { _, _ in
                NSCollectionLayoutSection(group: .horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(44)
                    ),
                    subitems: []
                ))
            },
            cellProvider: { _, _, _ in UICollectionViewCell() }
        )
        configuration.onSelect = onSelect
        configuration.onWillDisplay = onWillDisplay
        configuration.onPrefetch = onPrefetch
        configuration.onCancelPrefetch = onCancelPrefetch
        return CollectionViewController(configuration: configuration)
    }
}
