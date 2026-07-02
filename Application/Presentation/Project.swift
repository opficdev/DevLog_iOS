import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "Presentation",
    bundleId: "com.opfic.DevLog.Presentation",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.presentationPackages,
    dependencies: [
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Core", path: "../Core"),
        .project(target: "PresentationShared", path: "Shared"),
    ] + DevLogPackages.presentationPackageDependencies,
    hasTests: true
)
