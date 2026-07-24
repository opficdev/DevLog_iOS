//
//  ITunesLookupEndpoint.swift
//  Infra
//
//  Created by opfic on 7/24/26.
//

import Nexa

struct ITunesLookupEndpoint: NXEndpoint {
    static let timestampQueryKey = "timestamp"
    let timestamp: Int
    var method: NXHTTPMethod { .get }
    var path: String { "" }

    func configure(
        _ builder: NXTypedRequestBuilder<ITunesLookupResponse>
    ) -> NXTypedRequestBuilder<ITunesLookupResponse> {
        builder
            .query(Self.timestampQueryKey, timestamp)
            .accept("application/json")
    }
}
