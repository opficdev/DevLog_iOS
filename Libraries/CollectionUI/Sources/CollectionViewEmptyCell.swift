//
//  CollectionViewEmptyCell.swift
//  CollectionUI
//
//  Created by opfic on 8/20/26.
//

import UIKit

final class CollectionViewEmptyCell: UICollectionViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()
        isUserInteractionEnabled = false
    }
}
