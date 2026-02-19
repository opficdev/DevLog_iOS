//
//  WebPageMapping.swift
//  DevLog
//
//  Created by 최윤진 on 2/19/26.
//

extension WebPageResponse {
    func toDomain() -> WebPage {
        WebPage(
            title: title,
            url: url,
            displayURL: displayURL,
            imageURL: imageURL
        )
    }
}
