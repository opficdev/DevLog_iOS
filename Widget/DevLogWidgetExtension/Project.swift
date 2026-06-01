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
            deploymentTargets: .iOS("17.0"),
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
                .generated("Derived/Sources/TuistAssets+DevLogWidgetExtension.swift"),
                .generated("Derived/Sources/TuistBundle+DevLogWidgetExtension.swift"),
            ],
            resources: [
                "Resource/Assets.xcassets",
                "Resource/Localizable.xcstrings",
            ],
            entitlements: .file(path: "Resource/DevLogWidget.entitlements"),
            scripts: [
                .pre(
                    script: """
                    mkdir -p "$SRCROOT/Derived/Sources"
                    cat <<'EOF' > "$SRCROOT/Derived/Sources/TuistAssets+DevLogWidgetExtension.swift"
                    // swiftlint:disable:this file_name
                    // Generated workaround for Tuist 4.194.4 widget extension source reference.

                    import Foundation
                    EOF
                    cat <<'EOF' > "$SRCROOT/Derived/Sources/TuistBundle+DevLogWidgetExtension.swift"
                    // swiftlint:disable:this file_name
                    // Generated workaround for Tuist 4.194.4 widget extension source reference.

                    import Foundation
                    EOF
                    """,
                    name: "Generate Widget Accessors",
                    outputPaths: [
                        "Derived/Sources/TuistAssets+DevLogWidgetExtension.swift",
                        "Derived/Sources/TuistBundle+DevLogWidgetExtension.swift",
                    ],
                    basedOnDependencyAnalysis: false
                ),
            ],
            dependencies: [
                .project(target: "DevLogWidgetCore", path: "../DevLogWidgetCore"),
            ],
            settings: .devlog(
                versionXcconfigPath: "../../Application/Shared/Version.xcconfig",
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                ]
            )
        ),
    ]
)
