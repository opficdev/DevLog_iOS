import ProjectDescription
import ProjectDescriptionHelpers

let versionXcconfigPath = Path("../Shared/Version.xcconfig")
let frameworkInfoPlistPath = Path("../Shared/InfoPlists/Framework-Info.plist")
let testsInfoPlistPath = Path("../Shared/InfoPlists/UnitTests-Info.plist")

let frameworkBuildSettings = Settings.devlog(
    versionXcconfigPath: versionXcconfigPath,
    base: [
        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
        "OTHER_LIBTOOLFLAGS": "$(inherited) -no_warning_for_no_symbols"
    ],
    debug: [
        "DEBUG_INFORMATION_FORMAT": "dwarf"
    ],
    staging: [
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym"
    ],
    release: [
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym"
    ]
)

let project = Project(
    name: "Presentation",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: DevLogPackages.presentationPackages,
    settings: .devlogProject(versionXcconfigPath: versionXcconfigPath),
    targets: [
        .target(
            name: "PresentationShared",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.PresentationShared",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["PresentationShared/Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "PresentationShared/Sources",
                    configPath: "PresentationShared/Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .package(product: "ComposableArchitecture"),
                .package(product: "MarkdownUI"),
                .package(product: "OrderedCollections")
            ],
            settings: frameworkBuildSettings
        ),
        .target(
            name: "HomeTab",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.HomeTab",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["HomeTab/Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "HomeTab/Sources",
                    configPath: "HomeTab/Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "PresentationShared")
            ],
            settings: frameworkBuildSettings
        ),
        .target(
            name: "HomeTabTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.HomeTabTests",
            infoPlist: .file(path: testsInfoPlistPath),
            sources: ["HomeTab/Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "HomeTab/Tests",
                    configPath: "HomeTab/Tests/.swiftlint.yml"
                )
            ],
            dependencies: [
                .target(name: "HomeTab"),
                .target(name: "PresentationShared")
            ],
            settings: .devlog(
                base: [
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_TARGET_NAME": "HomeTab"
                ]
            )
        ),
        .target(
            name: "TodayTab",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.TodayTab",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["TodayTab/Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "TodayTab/Sources",
                    configPath: "TodayTab/Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "PresentationShared")
            ],
            settings: frameworkBuildSettings
        ),
        .target(
            name: "TodayTabTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.TodayTabTests",
            infoPlist: .file(path: testsInfoPlistPath),
            sources: ["TodayTab/Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "TodayTab/Tests",
                    configPath: "TodayTab/Tests/.swiftlint.yml"
                )
            ],
            dependencies: [
                .target(name: "TodayTab"),
                .target(name: "PresentationShared")
            ],
            settings: .devlog(
                base: [
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_TARGET_NAME": "TodayTab"
                ]
            )
        ),
        .target(
            name: "Presentation",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.Presentation",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Sources",
                    configPath: "Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "HomeTab"),
                .target(name: "TodayTab"),
                .target(name: "PresentationShared")
            ],
            settings: frameworkBuildSettings
        ),
        .target(
            name: "PresentationTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.PresentationTests",
            infoPlist: .file(path: testsInfoPlistPath),
            sources: ["Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Tests",
                    configPath: "Tests/.swiftlint.yml"
                )
            ],
            dependencies: [
                .target(name: "Presentation")
            ],
            settings: .devlog(
                base: [
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_TARGET_NAME": "Presentation"
                ]
            )
        )
    ]
)
