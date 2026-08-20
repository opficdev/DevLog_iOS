import UIKit

// UIKit swipe action을 적용할 방향
public enum CollectionSwipeActionsEdge: Equatable, Sendable {
    // cell의 좌측에서 우측 방향 swipe action
    case leading
    // cell의 우측에서 좌측 방향 swipe action
    case trailing
}

struct CollectionSwipeActions<ItemIdentifier> where ItemIdentifier: Hashable & Sendable {
    let edge: CollectionSwipeActionsEdge
    let allowsFullSwipe: Bool
    let actions: (ItemIdentifier) -> [UIContextualAction]
}
