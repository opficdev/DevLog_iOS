//
//  CollectionView.swift
//  CollectionUI
//
//  Created by opfic on 8/20/26.
//

import SwiftUI
import UIKit

// SwiftUI 화면과 UIKit collection controller를 연결한다.
@MainActor
public struct CollectionView<SectionIdentifier, ItemIdentifier>: UIViewControllerRepresentable
where SectionIdentifier: Hashable & Sendable, ItemIdentifier: Hashable & Sendable {
    var configuration: CollectionViewConfiguration<SectionIdentifier, ItemIdentifier>

    // 표시할 식별자 snapshot과 UIKit layout·cell provider를 지정해 container를 생성한다.
    public init(
        snapshot: CollectionRenderingSnapshot<SectionIdentifier, ItemIdentifier>,
        layoutProvider: @escaping (SectionIdentifier, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection,
        cellProvider: @escaping (UICollectionView, IndexPath, ItemIdentifier) -> UICollectionViewCell?
    ) {
        configuration = CollectionViewConfiguration(
            snapshot: snapshot,
            layoutProvider: layoutProvider,
            cellProvider: cellProvider
        )
    }

    // UIKit collection controller를 생성한다.
    public func makeUIViewController(context: Context) -> UIViewController {
        CollectionViewController(configuration: configuration)
    }

    // 최신 rendering 입력과 provider를 UIKit controller에 반영한다.
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? CollectionViewController)?.update(configuration: configuration)
    }
}
