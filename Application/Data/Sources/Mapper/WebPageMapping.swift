//
//  WebPageMapping.swift
//  Data
//
//  Created by 최윤진 on 2/19/26.
//

import Foundation
import Domain

public extension WebPageResponse {
    func toDomain() throws -> WebPage {
        guard let url = URL(string: url) else {
            throw DataLayerError.invalidData("WebPageResponse.url is invalid: \(url)")
        }
        guard let displayURL = URL(string: displayURL) else {
            throw DataLayerError.invalidData("WebPageResponse.displayURL is invalid: \(displayURL)")
        }
        let imageURL: URL?
        if !self.imageURL.isEmpty {
            imageURL = URL(string: self.imageURL)
        } else {
            imageURL = nil
        }
        return WebPage(
            id: id,
            title: title,
            url: url,
            displayURL: displayURL,
            imageURL: imageURL
        )
    }
}
