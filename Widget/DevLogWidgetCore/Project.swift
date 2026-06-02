import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogWidgetCore",
    bundleId: "com.opfic.DevLog.DevLogWidgetCore",
    versionXcconfigPath: "../../Application/Shared/Version.xcconfig",
    packages: DevLogPackages.lintOnlyPackages,
    dependencies: [
        .project(target: "DevLogCore", path: "../../Application/DevLogCore"),
    ],
    hasTests: true
)
