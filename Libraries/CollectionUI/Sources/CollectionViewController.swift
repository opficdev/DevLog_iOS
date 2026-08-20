//
//  CollectionViewController.swift
//  CollectionUI
//
//  Created by opfic on 8/20/26.
//

import UIKit

@MainActor
final class CollectionViewController<SectionIdentifier, ItemIdentifier>: UIViewController,
    UICollectionViewDelegate,
    UICollectionViewDataSourcePrefetching
where SectionIdentifier: Hashable & Sendable, ItemIdentifier: Hashable & Sendable {
    private static var emptyCellReuseIdentifier: String { "CollectionViewEmptyCell" }

    private let collectionView: UICollectionView
    private var configuration: CollectionViewConfiguration<SectionIdentifier, ItemIdentifier>
    private var dataSource: UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>!
    private var appliedSnapshot: CollectionRenderingSnapshot<SectionIdentifier, ItemIdentifier>?
    private var prefetchedItemIdentifiers = Set<ItemIdentifier>()
    private var refreshTask: Task<Void, Never>?

    private struct ScrollAnchor {
        let itemIdentifier: ItemIdentifier
        let relativeOffset: CGPoint
    }

    private struct PreservedState {
        let selectedItemIdentifiers: [ItemIdentifier]
        let scrollAnchor: ScrollAnchor?
    }

    init(configuration: CollectionViewConfiguration<SectionIdentifier, ItemIdentifier>) {
        self.configuration = configuration
        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout { _, _ in nil }
        )
        super.init(nibName: nil, bundle: nil)
        configureCollectionView()
        configureDataSource()
        configureLayout()
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        updateRefreshControl()
        applySnapshotIfNeeded()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = collectionView
    }

    func update(configuration: CollectionViewConfiguration<SectionIdentifier, ItemIdentifier>) {
        guard validates(configuration.snapshot) else {
            return
        }
        self.configuration = configuration
        collectionView.collectionViewLayout.invalidateLayout()
        updateRefreshControl()
        applySnapshotIfNeeded()
    }

    func dismantle() {
        refreshTask?.cancel()
        refreshTask = nil
        collectionView.delegate = nil
        collectionView.prefetchDataSource = nil
        collectionView.refreshControl = nil
        dataSource.supplementaryViewProvider = nil
    }

    func snapshot() -> NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier> {
        dataSource.snapshot()
    }

    private func configureCollectionView() {
        collectionView.register(
            CollectionViewEmptyCell.self,
            forCellWithReuseIdentifier: Self.emptyCellReuseIdentifier
        )
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let cell = self?.configuration.cellProvider(collectionView, indexPath, itemIdentifier) else {
                return self?.emptyCell(in: collectionView, for: indexPath, itemIdentifier: itemIdentifier)
            }
            return cell
        }
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard
                let self,
                let sectionIdentifier = self.sectionIdentifier(at: indexPath.section)
            else { return nil }
            return self.configuration.supplementaryViewProvider?(
                collectionView,
                kind,
                indexPath,
                sectionIdentifier
            )
        }
    }

    private func configureLayout() {
        collectionView.setCollectionViewLayout(
            UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
                guard let sectionIdentifier = self?.sectionIdentifier(at: sectionIndex) else {
                    return nil
                }
                return self?.configuration.layoutProvider(sectionIdentifier, environment)
            },
            animated: false
        )
    }

    private func updateRefreshControl() {
        guard configuration.refreshAction != nil else {
            collectionView.refreshControl = nil
            return
        }

        guard collectionView.refreshControl == nil else {
            return
        }
        let refreshControl = UIRefreshControl()
        refreshControl.addAction(UIAction { [weak self] _ in
            self?.refresh()
        }, for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    private func refresh() {
        guard let action = configuration.refreshAction else {
            collectionView.refreshControl?.endRefreshing()
            return
        }
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await action()
            guard !Task.isCancelled else { return }
            self?.collectionView.refreshControl?.endRefreshing()
        }
    }

    private func applySnapshotIfNeeded() {
        let snapshot = configuration.snapshot
        let requiresStructuralUpdate = !hasSameStructure(snapshot, appliedSnapshot)
        let hasReconfiguredItems = !snapshot.reconfiguredItemIdentifiers.isEmpty
        guard requiresStructuralUpdate || hasReconfiguredItems else {
            return
        }

        guard validates(snapshot) else {
            return
        }

        let diffableSnapshot = makeDiffableSnapshot(from: snapshot)
        if appliedSnapshot == nil {
            dataSource.applySnapshotUsingReloadData(diffableSnapshot)
        } else {
            let preservedState = makePreservedState()
            dataSource.apply(diffableSnapshot, animatingDifferences: true) { [weak self] in
                self?.restore(preservedState)
            }
        }
        appliedSnapshot = CollectionRenderingSnapshot(sections: snapshot.sections)
    }

    private func hasSameStructure(
        _ lhs: CollectionRenderingSnapshot<SectionIdentifier, ItemIdentifier>,
        _ rhs: CollectionRenderingSnapshot<SectionIdentifier, ItemIdentifier>?
    ) -> Bool {
        lhs.sections == rhs?.sections
    }

    func makeDiffableSnapshot(
        from renderingSnapshot: CollectionRenderingSnapshot<SectionIdentifier, ItemIdentifier>
    ) -> NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier> {
        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>()

        for section in renderingSnapshot.sections {
            snapshot.appendSections([section.identifier])
            snapshot.appendItems(section.itemIdentifiers, toSection: section.identifier)
        }

        let identifiers = renderingSnapshot.reconfiguredItemIdentifiers.filter {
            snapshot.indexOfItem($0) != nil
        }
        snapshot.reconfigureItems(Array(identifiers))
        return snapshot
    }

    private func validates(
        _ snapshot: CollectionRenderingSnapshot<SectionIdentifier, ItemIdentifier>
    ) -> Bool {
        var sectionIdentifiers = Set<SectionIdentifier>()
        var itemIdentifiers = Set<ItemIdentifier>()

        for section in snapshot.sections {
            guard sectionIdentifiers.insert(section.identifier).inserted else {
                assertionFailure("CollectionRenderingSnapshot contains a duplicated section identifier.")
                return false
            }

            for itemIdentifier in section.itemIdentifiers {
                guard itemIdentifiers.insert(itemIdentifier).inserted else {
                    assertionFailure("CollectionRenderingSnapshot contains a duplicated item identifier.")
                    return false
                }
            }
        }
        return true
    }

    private func sectionIdentifier(at index: Int) -> SectionIdentifier? {
        let sections = appliedSnapshot?.sections ?? configuration.snapshot.sections
        guard sections.indices.contains(index) else {
            return nil
        }
        return sections[index].identifier
    }

    private func makePreservedState() -> PreservedState {
        let selectedItemIdentifiers = (collectionView.indexPathsForSelectedItems ?? []).compactMap {
            dataSource.itemIdentifier(for: $0)
        }
        return PreservedState(
            selectedItemIdentifiers: selectedItemIdentifiers,
            scrollAnchor: makeScrollAnchor()
        )
    }

    private func makeScrollAnchor() -> ScrollAnchor? {
        collectionView.layoutIfNeeded()
        let indexPaths = collectionView.indexPathsForVisibleItems
        let indexPath = indexPaths.min { lhs, rhs in
            let lhsOrigin = collectionView.layoutAttributesForItem(at: lhs)?.frame.origin ?? .zero
            let rhsOrigin = collectionView.layoutAttributesForItem(at: rhs)?.frame.origin ?? .zero
            return lhsOrigin.y == rhsOrigin.y ? lhsOrigin.x < rhsOrigin.x : lhsOrigin.y < rhsOrigin.y
        }
        guard
            let indexPath,
            let itemIdentifier = dataSource.itemIdentifier(for: indexPath),
            let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        else { return nil }
        return ScrollAnchor(
            itemIdentifier: itemIdentifier,
            relativeOffset: CGPoint(
                x: attributes.frame.minX - collectionView.contentOffset.x,
                y: attributes.frame.minY - collectionView.contentOffset.y
            )
        )
    }

    private func restore(_ state: PreservedState) {
        collectionView.layoutIfNeeded()
        restoreSelection(state.selectedItemIdentifiers)
        restoreScrollPosition(state.scrollAnchor)
    }

    private func restoreSelection(_ itemIdentifiers: [ItemIdentifier]) {
        for itemIdentifier in itemIdentifiers {
            guard let indexPath = dataSource.indexPath(for: itemIdentifier) else { continue }
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }

    private func restoreScrollPosition(_ anchor: ScrollAnchor?) {
        guard
            let anchor,
            let indexPath = dataSource.indexPath(for: anchor.itemIdentifier),
            let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        else {
            clampContentOffset()
            return
        }
        let adjustedInset = collectionView.adjustedContentInset
        let maximumOffset = CGPoint(
            x: max(
                -adjustedInset.left,
                collectionView.contentSize.width - collectionView.bounds.width + adjustedInset.right
            ),
            y: max(
                -adjustedInset.top,
                collectionView.contentSize.height - collectionView.bounds.height + adjustedInset.bottom
            )
        )
        let offset = CGPoint(
            x: min(maximumOffset.x, max(-adjustedInset.left, attributes.frame.minX - anchor.relativeOffset.x)),
            y: min(maximumOffset.y, max(-adjustedInset.top, attributes.frame.minY - anchor.relativeOffset.y))
        )
        collectionView.setContentOffset(offset, animated: false)
    }

    private func clampContentOffset() {
        let adjustedInset = collectionView.adjustedContentInset
        let maximumOffset = CGPoint(
            x: max(
                -adjustedInset.left,
                collectionView.contentSize.width - collectionView.bounds.width + adjustedInset.right
            ),
            y: max(
                -adjustedInset.top,
                collectionView.contentSize.height - collectionView.bounds.height + adjustedInset.bottom
            )
        )
        let offset = CGPoint(
            x: min(maximumOffset.x, max(-adjustedInset.left, collectionView.contentOffset.x)),
            y: min(maximumOffset.y, max(-adjustedInset.top, collectionView.contentOffset.y))
        )
        collectionView.setContentOffset(offset, animated: false)
    }

    private func emptyCell(
        in collectionView: UICollectionView,
        for indexPath: IndexPath,
        itemIdentifier: ItemIdentifier
    ) -> UICollectionViewCell {
        #if DEBUG
        assertionFailure("CollectionUI cell provider did not return a cell for \(itemIdentifier).")
        #endif
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.emptyCellReuseIdentifier,
            for: indexPath
        )
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath) else { return }
        configuration.onSelect?(itemIdentifier)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath) else { return }
        prefetchedItemIdentifiers.remove(itemIdentifier)
        configuration.onWillDisplay?(itemIdentifier)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        configuration.onScroll?(scrollView.contentOffset)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        leadingSwipeActionsConfigurationForItemAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        swipeActionsConfiguration(for: indexPath, edge: .leading)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        trailingSwipeActionsConfigurationForItemAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        swipeActionsConfiguration(for: indexPath, edge: .trailing)
    }
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let identifiers = indexPaths.compactMap(dataSource.itemIdentifier).filter {
            prefetchedItemIdentifiers.insert($0).inserted
        }
        guard !identifiers.isEmpty else { return }
        configuration.onPrefetch?(identifiers)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let identifiers = indexPaths.compactMap(dataSource.itemIdentifier).filter {
            prefetchedItemIdentifiers.remove($0) != nil
        }
        guard !identifiers.isEmpty else { return }
        configuration.onCancelPrefetch?(identifiers)
    }

    private func swipeActionsConfiguration(
        for indexPath: IndexPath,
        edge: CollectionSwipeActionsEdge
    ) -> UISwipeActionsConfiguration? {
        guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let configurations = configuration.swipeActions.filter { $0.edge == edge }
        let actions = configurations.flatMap { $0.actions(itemIdentifier) }
        guard !actions.isEmpty else { return nil }
        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = configurations.allSatisfy(\.allowsFullSwipe)
        return configuration
    }
}
