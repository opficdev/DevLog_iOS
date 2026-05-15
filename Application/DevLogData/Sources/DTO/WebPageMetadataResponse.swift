//
//  WebPageMetadataResponse.swift
//  DevLog
//
//  Created by 최윤진 on 2/20/26.
//

public struct WebPageMetadataResponse {
    public let title: String
    public let displayURL: String
    public let imageURL: String

    public init(
        title: String,
        displayURL: String,
        imageURL: String
    ) {
        self.title = title
        self.displayURL = displayURL
        self.imageURL = imageURL
    }
}
