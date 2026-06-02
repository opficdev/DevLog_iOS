//
//  WebPageItem.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 2/9/26.
//

import SwiftUI
import DevLogDomain

public struct WebPageItem: Identifiable, Hashable {
    private let metadata: WebPage
    public var isHidden = false

    public init(from metadata: WebPage) {
        self.metadata = metadata
    }

    public var id: URL { metadata.url }
    public var title: String { metadata.title ?? String(localized: "web_page_missing_title") }
    public var url: URL { metadata.url }
    public var displayURL: String { metadata.displayURL.absoluteString }
    public var imageURL: URL? { metadata.imageURL }
}
