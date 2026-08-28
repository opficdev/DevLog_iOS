//
//  ErrorMapping.swift
//  Data
//
//  Created by opfic on 5/16/26.
//

import Domain

extension Error {
    func toDomain() -> Error {
        switch self as? DataLayerError {
        case .notAuthenticated:
            return AuthError.notAuthenticated
        case .failedToUnlinkLastProvider:
            return AuthError.failedToUnlinkLastProvider
        case .linkCredentialAlreadyInUse:
            return AuthError.linkCredentialAlreadyInUse
        case .developmentRecordDraftConflict:
            return DomainLayerError.developmentRecordDraftConflict
        case .invalidData(let context):
            return DomainLayerError.invalidData(context: context)
        case .none:
            return self
        }
    }
}
