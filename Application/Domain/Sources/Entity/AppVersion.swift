//
//  AppVersion.swift
//  Domain
//
//  Created by opfic on 7/22/26.
//

public struct AppVersion: Comparable {
    private let components: [Int]

    public init(marketingVersion: String, buildNumber: String) throws {
        try self.init("\(marketingVersion).\(buildNumber)")
    }

    init(_ value: String) throws {
        let rawComponents = value.split(separator: ".", omittingEmptySubsequences: false)
        guard !rawComponents.isEmpty,
              rawComponents.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else {
            throw DomainLayerError.invalidData(context: "appVersion")
        }

        let components = rawComponents.compactMap { Int($0) }
        guard components.count == rawComponents.count else {
            throw DomainLayerError.invalidData(context: "appVersion")
        }
        self.components = components
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)

        for index in 0..<count {
            let lhsComponent = index < lhs.components.count ? lhs.components[index] : 0
            let rhsComponent = index < rhs.components.count ? rhs.components[index] : 0
            guard lhsComponent != rhsComponent else { continue }
            return lhsComponent < rhsComponent
        }
        return false
    }
}
