//
//  WebPageItem.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

import SwiftUI

struct WebPageItem: Identifiable, Hashable {
    private let metadata: WebPage
    var isHidden = false

    init(from metadata: WebPage) {
        self.metadata = metadata
    }

    var id: URL { metadata.url }
    var title: String { metadata.title ?? String(localized: "web_page_missing_title") }
    var url: URL { metadata.url }
    var displayURL: String { metadata.displayURL.absoluteString }
    var imageURL: URL? { metadata.imageURL }
}
