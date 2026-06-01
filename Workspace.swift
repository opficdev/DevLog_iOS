import ProjectDescription

let workspace = Workspace(
    name: "DevLog",
    projects: [
        "Application/DevLogApp",
        "Application/DevLogCore",
        "Application/DevLogData",
        "Application/DevLogDomain",
        "Application/DevLogInfra",
        "Application/DevLogPersistence",
        "Application/DevLogPresentation",
        "Widget/DevLogWidgetCore",
        "Widget/DevLogWidgetExtension",
    ],
    generationOptions: .options(
        lastXcodeUpgradeCheck: "26.5.0"
    )
)
