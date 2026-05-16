//
//  ErrorMapping.swift
//  DevLogData
//
//  Created by opfic on 5/16/26.
//

import DevLogDomain

extension Error {
    func toDomain() -> Error {
        switch self as? DataLayerError {
        case .notAuthenticated:
            return AuthError.notAuthenticated
        case .linkCredentialAlreadyInUse:
            return AuthError.linkCredentialAlreadyInUse
        case .none:
            return self
        }
    }
}
