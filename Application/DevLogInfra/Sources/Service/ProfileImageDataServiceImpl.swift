//
//  ProfileImageDataServiceImpl.swift
//  DevLogInfra
//
//  Created by opfic on 6/11/26.
//

import Foundation
import Nexa
import DevLogData

final class ProfileImageDataServiceImpl: ProfileImageDataService {
    func fetchImageData(from url: URL) async throws -> Data {
        try await NXAPIClient(
            configuration: NXClientConfiguration(baseURL: url)
        )
        .get(url.absoluteString)
        .timeout(10)
        .intercept(ProfileImageDataCachePolicyInterceptor())
        .validate(.successStatusCode)
        .raw()
        .data
    }
}

private struct ProfileImageDataCachePolicyInterceptor: NXHTTPInterceptor {
    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        var request = context.request
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return try await next(context.replacingRequest(request))
    }
}
