//
//  WebPageResponse.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

import FirebaseFirestore

struct WebPageRequest: Encodable {
    let title: String
    let url: String
    let displayURL: String
    let imageURL: String
}

struct WebPageResponse: Decodable {
    @DocumentID var id: String?
    let title: String
    let url: String
    let displayURL: String
    let imageURL: String
}
