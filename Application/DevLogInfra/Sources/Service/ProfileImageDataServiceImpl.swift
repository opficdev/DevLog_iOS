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
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.ProfileImageDataServiceImpl"

        enum Code: Int {
            case fetchImageData = 1
        }
    }

    func fetchImageData(from url: URL) async throws -> Data {
        do {
            return try await NXAPIClient(
                configuration: NXClientConfiguration(baseURL: url)
            )
            .get()
            .timeout(10)
            .intercept(ProfileImageDataCachePolicyInterceptor())
            .validate(.successStatusCode)
            .raw()
            .data
        } catch {
            FirebaseCrashlyticsHelper.record(
                error,
                domain: CrashlyticsError.domain,
                code: CrashlyticsError.Code.fetchImageData.rawValue
            )
            throw error
        }
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
