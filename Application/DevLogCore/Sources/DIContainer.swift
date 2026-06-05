//
//  DIContainer.swift
//  DevLogCore
//
//  Created by opfic on 5/15/26.
//

import Foundation

public struct DependencyName: Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

public enum DependencyScope {
    case singleton
    case transient
}

public protocol DIContainer: Sendable {
    func register<T>(
        _ type: T.Type,
        name: DependencyName?,
        scope: DependencyScope,
        _ factory: @escaping () -> T
    )

    func resolve<T>(_ type: T.Type, name: DependencyName?) -> T
}

public extension DIContainer {
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

public final class AppDIContainer: DIContainer, @unchecked Sendable {
    public static let `default` = AppDIContainer()

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

    public func register<T>(
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

    public func resolve<T>(_ type: T.Type, name: DependencyName? = nil) -> T {
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
