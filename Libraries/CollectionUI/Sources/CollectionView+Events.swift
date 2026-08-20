import SwiftUI
import UIKit

public extension CollectionView {
    // item 선택 시 전달할 동작 지정
    func onSelect(_ action: @escaping (ItemIdentifier) -> Void) -> Self {
        var view = self
        view.configuration.onSelect = action
        return view
    }

    // item이 표시되기 시작할 때 전달할 동작 지정
    func onWillDisplay(_ action: @escaping (ItemIdentifier) -> Void) -> Self {
        var view = self
        view.configuration.onWillDisplay = action
        return view
    }

    // item 선준비를 시작할 때 전달할 동작 지정
    func onPrefetch(_ action: @escaping ([ItemIdentifier]) -> Void) -> Self {
        var view = self
        view.configuration.onPrefetch = action
        return view
    }

    // item 선준비를 취소할 때 전달할 동작 지정
    func onCancelPrefetch(_ action: @escaping ([ItemIdentifier]) -> Void) -> Self {
        var view = self
        view.configuration.onCancelPrefetch = action
        return view
    }

    // scroll 위치가 바뀔 때 전달할 동작 지정
    func onScroll(_ action: @escaping (CGPoint) -> Void) -> Self {
        var view = self
        view.configuration.onScroll = action
        return view
    }
}
