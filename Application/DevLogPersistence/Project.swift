import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogPersistence",
    bundleId: "com.opfic.DevLog.DevLogPersistence",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    packages: DevLogPackages.lintOnlyPackages,
    dependencies: [
        .project(target: "DevLogData", path: "../DevLogData"),
        .project(target: "DevLogCore", path: "../DevLogCore"),
        .project(target: "DevLogWidgetCore", path: "../../Widget/DevLogWidgetCore"),
    ],
    hasTests: true
)
