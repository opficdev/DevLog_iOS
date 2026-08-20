//
//  CollectionView.swift
//  CollectionUI
//
//  Created by opfic on 8/20/26.
//

import SwiftUI
import UIKit

// SwiftUI 화면과 UIKit collection controller 연결
@MainActor
public struct CollectionView<SectionIdentifier, ItemIdentifier>: UIViewControllerRepresentable
where SectionIdentifier: Hashable & Sendable, ItemIdentifier: Hashable & Sendable {
    var configuration: CollectionViewConfiguration<SectionIdentifier, ItemIdentifier>

    // 표시할 식별자 snapshot과 UIKit layout·cell provider 지정
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

    // UIKit collection controller 생성
    public func makeUIViewController(context: Context) -> UIViewController {
        CollectionViewController(configuration: configuration)
    }

    // 최신 rendering 입력과 provider의 UIKit controller 반영
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? CollectionViewController)?.update(configuration: configuration)
    }

    // UIKit controller의 delegate와 진행 중인 작업 정리
    public static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {
        (uiViewController as? CollectionViewController<SectionIdentifier, ItemIdentifier>)?.dismantle()
    }
}
