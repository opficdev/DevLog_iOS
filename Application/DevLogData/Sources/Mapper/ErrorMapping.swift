//
//  ErrorMapping.swift
//  DevLogData
//
//  Created by opfic on 5/16/26.
//

import DevLogDomain

extension Error {
    func toDomain() -> Error {
        if case .notAuthenticated = self as? DataLayerError {
            return AuthError.notAuthenticated
        }

        return self
    }
}
