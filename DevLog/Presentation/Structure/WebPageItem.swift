//
//  WebPageItem.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

import SwiftUI

struct WebPageItem: Identifiable, Hashable {
    private let metadata: WebPage

    init(from metadata: WebPage) {
        self.metadata = metadata
    }

    var id: URL { metadata.url }
    var title: String { metadata.title ?? "웹페이지를 찾을 수 없습니다" }
    var url: URL { metadata.url }
    var displayURL: String { metadata.displayURL.absoluteString }
    var imageURL: URL? { metadata.imageURL }
}
