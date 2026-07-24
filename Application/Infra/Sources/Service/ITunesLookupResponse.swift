//
//  ITunesLookupResponse.swift
//  Infra
//
//  Created by opfic on 7/24/26.
//

struct ITunesLookupResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case results
    }

    private enum ResultCodingKeys: String, CodingKey {
        case version
    }

    let version: String?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var results = try container.nestedUnkeyedContainer(forKey: .results)

        guard !results.isAtEnd else {
            version = nil
            return
        }

        let result = try results.nestedContainer(keyedBy: ResultCodingKeys.self)
        version = try result.decodeIfPresent(String.self, forKey: .version)
    }
}
