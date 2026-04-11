//
//  WebPageMapping.swift
//  DevLog
//
//  Created by 최윤진 on 2/19/26.
//

import Foundation

extension WebPageResponse {
    func toDomain() throws -> WebPage {
        guard let url = URL(string: url) else {
            throw DataError.invalidData("WebPageResponse.url is invalid: \(url)")
        }
        guard let displayURL = URL(string: displayURL) else {
            throw DataError.invalidData("WebPageResponse.displayURL is invalid: \(displayURL)")
        }
        let imageURL: URL?
        if !self.imageURL.isEmpty {
            imageURL = URL(string: self.imageURL)
        } else {
            imageURL = nil
        }
        return WebPage(
            title: title,
            url: url,
            displayURL: displayURL,
            imageURL: imageURL
        )
    }
}
