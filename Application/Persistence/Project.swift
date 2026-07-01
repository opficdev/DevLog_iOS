import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "Persistence",
    bundleId: "com.opfic.DevLog.Persistence",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.defaultPackages,
    dependencies: [
        .project(target: "Data", path: "../Data"),
        .project(target: "Core", path: "../Core"),
    ],
    hasTests: true
)
