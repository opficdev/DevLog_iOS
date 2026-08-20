import ProjectDescription
import ProjectDescriptionHelpers

let deploymentSettings: SettingsDictionary = [
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "MARKETING_VERSION": "1.0.0",
]

let project = Project(
    name: "CollectionUI",
    packages: [],
    settings: .devlogProject(additionalBase: deploymentSettings),
    targets: [
        .target(
            name: "CollectionUI",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.opfic.DevLog.CollectionUI",
            infoPlist: .extendingDefault(
                with: [
                    "CFBundlePackageType": "FMWK",
                ]
            ),
            sources: [
                "Sources/**/*.swift",
            ],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Sources",
                    configPath: "Sources/.swiftlint.yml"
                ),
            ],
            dependencies: [],
            settings: .devlog(
                base: deploymentSettings
            )
        ),
        .target(
            name: "CollectionUITests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.CollectionUITests",
            infoPlist: .extendingDefault(
                with: [
                    "CFBundlePackageType": "BNDL",
                ]
            ),
            sources: [
                "Tests/**/*.swift",
            ],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Tests",
                    configPath: "Tests/.swiftlint.yml"
                ),
            ],
            dependencies: [
                .target(name: "CollectionUI"),
            ],
            settings: .devlog(
                base: deploymentSettings.merging(
                    [
                        "TEST_TARGET_NAME": "CollectionUI",
                    ]
                ) { _, new in new }
            )
        ),
    ]
)
