import SwiftUI
import UIKit

public extension CollectionView {
    // section 식별자로 supplementary view를 만들 동작 지정
    func supplementaryViews(
        _ provider: @escaping (UICollectionView, String, IndexPath, SectionIdentifier) -> UICollectionReusableView?
    ) -> Self {
        var view = self
        view.configuration.supplementaryViewProvider = provider
        return view
    }
}
