import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "DevLogWidgetExtension",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    settings: .devlogProject(versionXcconfigPath: "../../Application/Shared/Version.xcconfig"),
    targets: [
        .target(
            name: "DevLogWidgetExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "opfic.DevLog.DevLogWidget",
            infoPlist: .file(path: "Resource/Info.plist"),
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
