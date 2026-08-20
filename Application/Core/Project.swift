import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "Core",
    bundleId: "com.opfic.DevLog.Core",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: [],
    hasTests: false
)
