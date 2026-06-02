import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "DevLogWidgetExtension",
    options: .options(
        disableBundleAccessors: false,
        disableSynthesizedResourceAccessors: false
    ),
    settings: .devlogProject(versionXcconfigPath: "../../Application/Shared/Version.xcconfig"),
    targets: [
        .target(
            name: "DevLogWidgetExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "opfic.DevLog.DevLogWidget",
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                    "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                    ],
                ]
            ),
            sources: [
                .glob(
                    "**/*.swift",
                    excluding: [
                        "Derived/**",
                        "Project.swift",
                    ]
                ),
            ],
            resources: [
                "Resource/Assets.xcassets",
                "Resource/Localizable.xcstrings",
            ],
            entitlements: .file(path: "Resource/DevLogWidget.entitlements"),
            dependencies: [
                .project(target: "DevLogWidgetCore", path: "../DevLogWidgetCore"),
            ],
            settings: .devlog(
                versionXcconfigPath: "../../Application/Shared/Version.xcconfig",
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                ]
            )
        ),
    ]
)
