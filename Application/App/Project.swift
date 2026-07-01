import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: DevLogPackages.defaultPackages,
    settings: .devlogProject(versionXcconfigPath: "../Shared/Version.xcconfig"),
    targets: [
        .target(
            name: "App",
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
            ],
            dependencies: [
                .project(target: "Presentation", path: "../Presentation"),
                .project(target: "Persistence", path: "../Persistence"),
                .project(target: "Infra", path: "../Infra"),
                .project(target: "Widget", path: "../Widget"),
                .project(target: "Data", path: "../Data"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .project(target: "WidgetCore", path: "../../Widget/WidgetCore"),
                .project(target: "WidgetExtension", path: "../../Widget/WidgetExtension"),
            ],
            settings: .devlog(
                versionXcconfigPath: "Sources/Resource/App.xcconfig",
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "PRODUCT_MODULE_NAME": "App",
                ],
                debug: [
                    "APS_ENVIRONMENT": "development",
                    "DEBUG_INFORMATION_FORMAT": "dwarf",
                    "FIRESTORE_DATABASE_ID": "staging",
                    "INFOPLIST_KEY_FirebaseCrashlyticsCollectionEnabled": "NO",
                ],
                staging: [
                    "APS_ENVIRONMENT": "production",
                    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
                    "FIRESTORE_DATABASE_ID": "staging",
                    "INFOPLIST_KEY_FirebaseCrashlyticsCollectionEnabled": "YES",
                ],
                release: [
                    "APS_ENVIRONMENT": "production",
                    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
                    "FIRESTORE_DATABASE_ID": "prod",
                    "INFOPLIST_KEY_FirebaseCrashlyticsCollectionEnabled": "YES",
                ]
            )
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "opfic.AppTests",
            infoPlist: .file(path: "../Shared/InfoPlists/UnitTests-Info.plist"),
            sources: ["Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Tests",
                    configPath: "Tests/.swiftlint.yml"
                ),
            ],
            dependencies: [
                .target(name: "App"),
            ],
            settings: .devlog(
                base: [
                    "BUNDLE_LOADER": "$(TEST_HOST)",
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/DevLog.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DevLog",
                    "TEST_TARGET_NAME": "App",
                ]
            )
        ),
    ]
)
