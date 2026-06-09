import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogInfra",
    bundleId: "com.opfic.DevLog.DevLogInfra",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.infraPackages,
    dependencies: [
        .project(target: "DevLogData", path: "../DevLogData"),
        .project(target: "DevLogCore", path: "../DevLogCore"),
    ] + DevLogPackages.infraPackageDependencies,
    hasTests: true
)
