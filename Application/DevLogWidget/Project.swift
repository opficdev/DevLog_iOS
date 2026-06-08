import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogWidget",
    bundleId: "com.opfic.DevLog.DevLogWidget",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.defaultPackages,
    dependencies: [
        .project(target: "DevLogData", path: "../DevLogData"),
        .project(target: "DevLogCore", path: "../DevLogCore"),
    ],
    hasTests: true
)
