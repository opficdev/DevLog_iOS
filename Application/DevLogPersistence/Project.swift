import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogPersistence",
    bundleId: "com.opfic.DevLog.DevLogPersistence",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.defaultPackages,
    dependencies: [
        .project(target: "DevLogData", path: "../DevLogData"),
        .project(target: "DevLogCore", path: "../DevLogCore"),
        .project(target: "DevLogWidgetCore", path: "../../Widget/DevLogWidgetCore"),
    ],
    hasTests: true
)
