import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogWidgetCore",
    bundleId: "com.opfic.DevLog.DevLogWidgetCore",
    versionXcconfigPath: "../../Application/Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../../Application/Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../../Application/Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.defaultPackages,
    dependencies: [
        .project(target: "DevLogCore", path: "../../Application/DevLogCore"),
    ],
    hasTests: true
)
