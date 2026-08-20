# CollectionUI

`CollectionUI`는 SwiftUI 화면에서 UIKit `UICollectionView`를 연결하는 내부 공용 Library임.

```swift
CollectionView(
    snapshot: .init(sections: [
        .init(identifier: .default, itemIdentifiers: todos.map(\.id))
    ]),
    layoutProvider: { _, _ in makeTodoLayout() },
    cellProvider: { collectionView, indexPath, identifier in
        collectionView.dequeueConfiguredReusableCell(
            using: todoCellRegistration,
            for: indexPath,
            item: identifier
        )
    }
)
.onSelect { identifier in
    store.send(.view(.select(identifier)))
}
.swipeActions(edge: .trailing) { identifier in
    [deleteAction(identifier)]
}
.refreshable {
    await store.send(.view(.refresh)).finish()
}
```

Cell은 `UICollectionViewCell`과 UIKit `UIView`로만 구성하며, `UIHostingController`, `UIHostingConfiguration`, `AnyView`는 사용하지 않음.
