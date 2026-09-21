//
//  AvatarImageData.swift
//  ProfileTab
//
//  Created by opfic on 6/17/26.
//

import Foundation

struct AvatarImageData: Equatable {
    let id: Int
    let data: Data

    static func == (lhs: AvatarImageData, rhs: AvatarImageData) -> Bool {
        lhs.id == rhs.id
    }
}
