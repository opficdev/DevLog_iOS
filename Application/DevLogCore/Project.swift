import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogCore",
    bundleId: "com.opfic.DevLog.DevLogCore",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    packages: DevLogPackages.lintOnlyPackages,
    hasTests: false
)
