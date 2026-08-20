import SwiftUI

public extension CollectionView {
    // UIKit 새로고침 완료를 기다릴 비동기 동작을 지정한다.
    func refreshable(_ action: @escaping () async -> Void) -> Self {
        var view = self
        view.configuration.refreshAction = action
        return view
    }
}
