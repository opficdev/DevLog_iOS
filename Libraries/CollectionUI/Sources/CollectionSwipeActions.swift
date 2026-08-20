import UIKit

// UIKit swipe action을 적용할 방향을 나타낸다.
public enum CollectionSwipeActionsEdge: Equatable, Sendable {
    // cell의 앞쪽 swipe action을 나타낸다.
    case leading
    // cell의 뒤쪽 swipe action을 나타낸다.
    case trailing
}

struct CollectionSwipeActions<ItemIdentifier> where ItemIdentifier: Hashable & Sendable {
    let edge: CollectionSwipeActionsEdge
    let allowsFullSwipe: Bool
    let actions: (ItemIdentifier) -> [UIContextualAction]
}
