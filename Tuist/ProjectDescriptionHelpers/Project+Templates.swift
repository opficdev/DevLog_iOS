import ProjectDescription

public extension Project {
    static func devlogFramework(
        name: String,
        bundleId: String,
        versionXcconfigPath: Path,
        dependencies: [TargetDependency] = [],
        hasTests: Bool
    ) -> Project {
        var targets: [Target] = [
            .target(
                name: name,
                destinations: .iOS,
                product: .framework,
                bundleId: bundleId,
                deploymentTargets: .iOS("17.0"),
                infoPlist: .default,
                sources: ["Sources/**"],
                dependencies: dependencies + [DevLogPackages.swiftLintPlugin],
                settings: .devlog(
                    versionXcconfigPath: versionXcconfigPath,
                    base: [
                        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                    ]
                )
            ),
        ]

        if hasTests {
            targets.append(
                .testTarget(
                    name: "\(name)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    bundleId: "\(bundleId)Tests",
                    infoPlist: .default,
                    sources: ["Tests/**"],
                    dependencies: [
                        .target(name: name),
                    ],
                    settings: .devlog(
                        base: [
                            "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                            "TEST_TARGET_NAME": name,
                        ]
                    )
                )
            )
        }

        return Project(
            name: name,
            targets: targets
        )
    }
}
