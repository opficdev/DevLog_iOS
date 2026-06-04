import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogDomain",
    bundleId: "com.opfic.DevLog.DevLogDomain",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.defaultPackages,
    dependencies: [
        .project(target: "DevLogCore", path: "../DevLogCore"),
    ],
    hasTests: true
)
