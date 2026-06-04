import ProjectDescription

public extension Project {
    static func devlogFramework(
        name: String,
        bundleId: String,
        versionXcconfigPath: Path,
        frameworkInfoPlistPath: Path,
        testsInfoPlistPath: Path,
        packages: [Package] = DevLogPackages.defaultPackages,
        dependencies: [TargetDependency] = [],
        hasTests: Bool
    ) -> Project {
        var targets: [Target] = [
            .target(
                name: name,
                destinations: .iOS,
                product: .framework,
                bundleId: bundleId,
                infoPlist: .file(path: frameworkInfoPlistPath),
                sources: ["Sources/**/*.swift"],
                scripts: [
                    DevLogScripts.swiftLint(sourcePath: "Sources"),
                ],
                dependencies: dependencies,
                settings: .devlog(
                    versionXcconfigPath: versionXcconfigPath,
                    base: [
                        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
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
                    infoPlist: .file(path: testsInfoPlistPath),
                    sources: ["Tests/**/*.swift"],
                    dependencies: [
                        .target(name: name),
                    ],
                    settings: .devlog(
                        base: [
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
            settings: .devlogProject(versionXcconfigPath: versionXcconfigPath),
            targets: targets
        )
    }
}
