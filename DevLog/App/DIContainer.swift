//
//  DIContainer.swift
//  DevLog
//
//  Created by 최윤진 on 11/16/25.
//

import Foundation

struct DependencyName: Hashable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: String) {
        self.rawValue = value
    }
}

enum DependencyScope {
    case singleton
    case transient
}

protocol DIContainer {
    func register<T>(
        _ type: T.Type,
        name: DependencyName?,
        scope: DependencyScope,
        _ factory: @escaping () -> T
    )

    func resolve<T>(_ type: T.Type, name: DependencyName?) -> T
}

extension DIContainer {
    func register<T>(
        _ type: T.Type,
        name: DependencyName? = nil,
        scope: DependencyScope = .singleton,
        _ factory: @escaping () -> T
    ) {
        register(type, name: name, scope: scope, factory)
    }

    func resolve<T>(_ type: T.Type, name: DependencyName? = nil) -> T {
        resolve(type, name: name)
    }
}

final class AppDIContainer: DIContainer {
    static let shared = AppDIContainer()

    private let lock = NSRecursiveLock()

    private init() { }

    private struct Key: Hashable {
        let type: ObjectIdentifier
        let name: DependencyName?
    }

    private struct Registration {
        let scope: DependencyScope
        let factory: () -> Any
    }

    private var registrations = [Key: Registration]()
    private var singletons = [Key: Any]()

    func register<T>(
        _ type: T.Type,
        name: DependencyName? = nil,
        scope: DependencyScope = .singleton,
        _ factory: @escaping () -> T
    ) {
        lock.lock()
        defer { lock.unlock() }

        let key = Key(type: .init(type), name: name)
        registrations[key] = Registration(scope: scope, factory: factory)
    }

    func resolve<T>(_ type: T.Type, name: DependencyName? = nil) -> T {
        lock.lock()
        defer { lock.unlock() }

        let key = Key(type: .init(type), name: name)
        guard let registration = registrations[key] else { fatalError("\(type)에 대한 의존성이 등록되지 않았습니다.") }

        switch registration.scope {
        case .singleton:
            if let cached = singletons[key] as? T { return cached }
            guard let singleton = registration.factory() as? T else { fatalError("\(type) 생성 실패") }
            singletons[key] = singleton
            return singleton

        case .transient:
            guard let resolved = registration.factory() as? T else { fatalError("\(type) 생성 실패") }
            return resolved
        }
    }
}
