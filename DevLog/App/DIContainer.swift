//
//  DIContainer.swift
//  DevLog
//
//  Created by 최윤진 on 11/16/25.
//

import Foundation

final class DIContainer {
    static let shared = DIContainer()

    enum Scope {
        case singleton
        case transient
    }

    private var factories: [String: () -> Any] = [:]
    private var singletones: [String: Any] = [:]
    private var scopes: [String: Scope] = [:]

    private init() {}

    public func register<T>(
        type: T.Type,
        scope: Scope,
        factory: @escaping () -> T
    ) {
        let key = String(describing: type)
        factories[key] = factory
        scopes[key] = scope
    }

    public func resolve<T>(type: T.Type) -> T {
        let key = String(describing: type)

        if scopes[key] == .singleton,
           let cached = singletones[key] as? T {
            return cached
        }

        guard let factory = factories[key] else {
            fatalError("\(type) 의존성이 등록되지 않았습니다.")
        }

        let instance = factory()

        guard let typedInstance = instance as? T else {
            fatalError("\(type) 의존성의 타입이 일치하지 않습니다.")
        }

        if scopes[key] == .singleton {
            singletones[key] = typedInstance
        }

        return typedInstance
    }
}
