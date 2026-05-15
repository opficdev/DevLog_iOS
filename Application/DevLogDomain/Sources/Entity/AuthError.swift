//
//  AuthError.swift
//  DevLog
//
//  Created by opfic on 5/15/26.
//

public enum AuthError: Error {
    case notAuthenticated
    case failedToUnlinkLastProvider
    case emailNotFound
    case linkEmailNotFound
    case linkEmailMismatch
    case linkCredentialAlreadyInUse
    case unsupportedProvider
}
