import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "DevLogApp",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: DevLogPackages.defaultPackages,
    settings: .devlogProject(versionXcconfigPath: "../Shared/Version.xcconfig"),
    targets: [
        .target(
            name: "DevLogApp",
            destinations: .iOS,
            product: .app,
            productName: "DevLog",
            bundleId: "opfic.DevLog",
            infoPlist: .file(path: "Sources/Resource/Info.plist"),
            sources: ["Sources/**/*.swift"],
            resources: [
                "Sources/Resource/Assets.xcassets",
                "Sources/Resource/GoogleService-Info.plist",
                "Sources/Resource/Localizable.xcstrings",
            ],
            entitlements: .file(path: "Sources/Resource/DevLog.entitlements"),
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Sources",
                    configPath: "Sources/.swiftlint.yml"
                ),
                DevLogScripts.firebaseCrashlyticsDSYMUpload(),
            ],
            dependencies: [
                .project(target: "DevLogPresentation", path: "../DevLogPresentation"),
                .project(target: "DevLogPersistence", path: "../DevLogPersistence"),
                .project(target: "DevLogInfra", path: "../DevLogInfra"),
                .project(target: "DevLogWidget", path: "../DevLogWidget"),
                .project(target: "DevLogData", path: "../DevLogData"),
                .project(target: "DevLogDomain", path: "../DevLogDomain"),
                .project(target: "DevLogCore", path: "../DevLogCore"),
                .project(target: "DevLogWidgetCore", path: "../../Widget/DevLogWidgetCore"),
                .project(target: "DevLogWidgetExtension", path: "../../Widget/DevLogWidgetExtension"),
            ],
            settings: .devlog(
                versionXcconfigPath: "Sources/Resource/App.xcconfig",
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "PRODUCT_MODULE_NAME": "DevLogApp",
                ],
                debug: [
                    "APS_ENVIRONMENT": "development",
                    "DEBUG_INFORMATION_FORMAT": "dwarf",
                    "INFOPLIST_KEY_FirebaseCrashlyticsCollectionEnabled": "NO",
                ],
                release: [
                    "APS_ENVIRONMENT": "production",
                    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
                    "INFOPLIST_KEY_FirebaseCrashlyticsCollectionEnabled": "YES",
                ]
            )
        ),
        .target(
            name: "DevLogAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "opfic.DevLogAppTests",
            infoPlist: .file(path: "../Shared/InfoPlists/UnitTests-Info.plist"),
            sources: ["Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Tests",
                    configPath: "Tests/.swiftlint.yml"
                ),
            ],
            dependencies: [
                .target(name: "DevLogApp"),
            ],
            settings: .devlog(
                base: [
                    "BUNDLE_LOADER": "$(TEST_HOST)",
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/DevLog.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DevLog",
                    "TEST_TARGET_NAME": "DevLogApp",
                ]
            )
        ),
    ]
)
