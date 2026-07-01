import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "WidgetCore",
    bundleId: "com.opfic.DevLog.WidgetCore",
    versionXcconfigPath: "../../Application/Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../../Application/Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../../Application/Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.defaultPackages,
    dependencies: [
        .project(target: "Core", path: "../../Application/Core"),
    ],
    hasTests: true
)
