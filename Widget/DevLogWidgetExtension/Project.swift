import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "DevLogWidgetExtension",
    targets: [
        .target(
            name: "DevLogWidgetExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "opfic.DevLog.DevLogWidget",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .file(path: "Resource/Info.plist"),
            sources: ["**/*.swift"],
            resources: [
                "Resource/**",
                "!Resource/Info.plist",
                "!Resource/*.entitlements",
            ],
            entitlements: .file(path: "Resource/DevLogWidget.entitlements"),
            dependencies: [
                .project(target: "DevLogWidgetCore", path: "../DevLogWidgetCore"),
            ],
            settings: .devlog(
                versionXcconfigPath: "../../Application/Shared/Version.xcconfig",
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": DevLogSigning.teamID,
                    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                ]
            )
        ),
    ]
)
