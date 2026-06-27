//
//  WebPage.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/9/26.
//

import Foundation

public struct WebPage: Hashable {
    public let id: String
    public let title: String?
    public let url: URL
    public let displayURL: URL
    public let imageURL: URL?

    public init(
        id: String,
        title: String?,
        url: URL,
        displayURL: URL,
        imageURL: URL?
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.displayURL = displayURL
        self.imageURL = imageURL
    }
}
