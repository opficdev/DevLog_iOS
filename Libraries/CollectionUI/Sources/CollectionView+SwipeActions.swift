import SwiftUI
import UIKit

public extension CollectionView {
    // item 식별자로 UIKit swipe action을 만들 동작 추가
    func swipeActions(
        edge: CollectionSwipeActionsEdge = .trailing,
        allowsFullSwipe: Bool = true,
        actions: @escaping (ItemIdentifier) -> [UIContextualAction]
    ) -> Self {
        var view = self
        view.configuration.swipeActions.append(.init(
            edge: edge,
            allowsFullSwipe: allowsFullSwipe,
            actions: actions
        ))
        return view
    }
}
