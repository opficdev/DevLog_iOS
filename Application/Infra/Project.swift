import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "Infra",
    bundleId: "com.opfic.DevLog.Infra",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.infraPackages,
    dependencies: [
        .project(target: "Data", path: "../Data"),
        .project(target: "Core", path: "../Core"),
    ] + DevLogPackages.infraPackageDependencies,
    hasTests: true
)
