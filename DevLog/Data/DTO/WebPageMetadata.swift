//
//  WebPageMetadata.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

import Foundation

struct WebPageMetadata: Hashable {
    let title: String?
    let url: URL
    let displayURL: URL
    let imageURL: URL?

    func toDomain() -> WebPage {
        WebPage(
            title: title,
            url: url,
            displayURL: displayURL,
            imageURL: imageURL
        )
    }
}
