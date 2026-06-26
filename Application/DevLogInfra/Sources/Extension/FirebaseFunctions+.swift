//
//  FirebaseFunctions+.swift
//  DevLogInfra
//
//  Created by opfic on 3/16/26.
//

import FirebaseFunctions

extension Functions {
    func httpsCallable(_ name: some RawRepresentable<String>) -> FirebaseFunction {
        FirebaseFunction(callable: httpsCallable(name.rawValue))
    }
}

struct FirebaseFunction {
    private let callable: HTTPSCallable

    init(callable: HTTPSCallable) {
        self.callable = callable
    }

    func call(_ data: [String: Any] = [:]) async throws -> HTTPSCallableResult {
        try await callable.call(FirebaseConfiguration.callablePayload(data))
    }
}
