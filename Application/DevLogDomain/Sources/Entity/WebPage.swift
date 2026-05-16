//
//  WebPage.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/9/26.
//

import Foundation

public struct WebPage: Hashable {
    public let title: String?
    public let url: URL
    public let displayURL: URL
    public let imageURL: URL?

    public init(
        title: String?,
        url: URL,
        displayURL: URL,
        imageURL: URL?
    ) {
        self.title = title
        self.url = url
        self.displayURL = displayURL
        self.imageURL = imageURL
    }
}
