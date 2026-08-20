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
        configureRefreshControl()
        applySnapshotIfNeeded()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = collectionView
    }

    func update(configuration: CollectionViewConfiguration<SectionIdentifier, ItemIdentifier>) {
        self.configuration = configuration
        applySnapshotIfNeeded()
    }

    func dismantle() {
        refreshTask?.cancel()
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

    private func configureRefreshControl() {
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
        guard configuration.snapshot != appliedSnapshot else {
            return
        }

        guard validates(configuration.snapshot) else {
            return
        }

        let snapshot = makeDiffableSnapshot(from: configuration.snapshot)
        if appliedSnapshot == nil {
            dataSource.applySnapshotUsingReloadData(snapshot)
        } else {
            dataSource.apply(snapshot, animatingDifferences: true)
        }
        appliedSnapshot = configuration.snapshot
    }

    private func makeDiffableSnapshot(
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
