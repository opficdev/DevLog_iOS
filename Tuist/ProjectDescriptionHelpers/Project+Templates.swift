import ProjectDescription

public extension Project {
    static func devlogFramework(
        name: String,
        bundleId: String,
        versionXcconfigPath: Path,
        packages: [Package] = DevLogPackages.lintOnlyPackages,
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
                .target(
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
                            "TEST_TARGET_NAME": SettingValue(stringLiteral: name),
                        ]
                    )
                )
            )
        }

        return Project(
            name: name,
            options: .options(
                disableBundleAccessors: true,
                disableSynthesizedResourceAccessors: true
            ),
            packages: packages,
            targets: targets
        )
    }
}
