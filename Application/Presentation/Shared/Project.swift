import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "PresentationShared",
    bundleId: "com.opfic.DevLog.PresentationShared",
    versionXcconfigPath: "../../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../../Shared/InfoPlists/UnitTests-Info.plist",
    packages: DevLogPackages.defaultPackages,
    hasTests: false
)
