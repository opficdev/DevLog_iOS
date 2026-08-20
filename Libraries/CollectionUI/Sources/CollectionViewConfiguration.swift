//
//  CollectionViewConfiguration.swift
//  CollectionUI
//
//  Created by opfic on 8/20/26.
//

import UIKit

struct CollectionViewConfiguration<SectionIdentifier, ItemIdentifier>
where SectionIdentifier: Hashable & Sendable, ItemIdentifier: Hashable & Sendable {
    let snapshot: CollectionRenderingSnapshot<SectionIdentifier, ItemIdentifier>
    let layoutProvider: (SectionIdentifier, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection
    let cellProvider: (UICollectionView, IndexPath, ItemIdentifier) -> UICollectionViewCell?
    var onSelect: ((ItemIdentifier) -> Void)?
    var onWillDisplay: ((ItemIdentifier) -> Void)?
    var onPrefetch: (([ItemIdentifier]) -> Void)?
    var onCancelPrefetch: (([ItemIdentifier]) -> Void)?
    var onScroll: ((CGPoint) -> Void)?
    var swipeActions: [CollectionSwipeActions<ItemIdentifier>] = []
}
