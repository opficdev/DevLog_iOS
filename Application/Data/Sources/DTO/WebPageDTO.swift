//
//  WebPageDTO.swift
//  Data
//
//  Created by 최윤진 on 2/9/26.
//

import Foundation
import Domain

public struct WebPageRequest: Encodable {
    public let title: String
    public let url: String
    public let displayURL: String
    public let imageURL: String
    public let isDeleted: Bool

    public init(
        title: String,
        url: String,
        displayURL: String,
        imageURL: String,
        isDeleted: Bool
    ) {
        self.title = title
        self.url = url
        self.displayURL = displayURL
        self.imageURL = imageURL
        self.isDeleted = isDeleted
    }
}

public struct WebPageResponse {
    public let id: String
    public let title: String
    public let url: String
    public let displayURL: String
    public let imageURL: String

    public init(
        id: String,
        title: String,
        url: String,
        displayURL: String,
        imageURL: String
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.displayURL = displayURL
        self.imageURL = imageURL
    }
}
