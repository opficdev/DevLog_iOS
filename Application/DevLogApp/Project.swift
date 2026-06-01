import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "DevLogApp",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: DevLogPackages.lintOnlyPackages,
    targets: [
        .target(
            name: "DevLog",
            destinations: .iOS,
            product: .app,
            bundleId: "opfic.DevLog",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .file(path: "Sources/Resource/Info.plist"),
            sources: ["Sources/**"],
            resources: [
                .glob(
                    pattern: "Sources/Resource/**",
                    excluding: [
                        "Sources/Resource/Info.plist",
                        "Sources/Resource/*.entitlements",
                        "Sources/Resource/*.xcconfig",
                    ]
                ),
            ],
            entitlements: .file(path: "Sources/Resource/DevLog.entitlements"),
            dependencies: [
                .project(target: "DevLogPresentation", path: "../DevLogPresentation"),
                .project(target: "DevLogPersistence", path: "../DevLogPersistence"),
                .project(target: "DevLogInfra", path: "../DevLogInfra"),
                .project(target: "DevLogData", path: "../DevLogData"),
                .project(target: "DevLogDomain", path: "../DevLogDomain"),
                .project(target: "DevLogCore", path: "../DevLogCore"),
                .project(target: "DevLogWidgetCore", path: "../../Widget/DevLogWidgetCore"),
                .project(target: "DevLogWidgetExtension", path: "../../Widget/DevLogWidgetExtension"),
                DevLogPackages.swiftLintPlugin,
            ],
            settings: .devlog(
                versionXcconfigPath: "../Shared/Version.xcconfig",
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": DevLogSigning.teamID,
                    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                ]
            )
        ),
        .target(
            name: "DevLogAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "opfic.DevLogAppTests",
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "DevLog"),
            ],
            settings: .devlog(
                base: [
                    "BUNDLE_LOADER": "$(TEST_HOST)",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": DevLogSigning.teamID,
                    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/DevLog.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DevLog",
                    "TEST_TARGET_NAME": "DevLog",
                ]
            )
        ),
    ]
)
