import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "Infra",
    bundleId: "com.opfic.DevLog.Infra",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: [],
    dependencies: [
        .project(target: "Data", path: "../Data"),
        .project(target: "Core", path: "../Core"),
        .project(target: "ThirdParty", path: "../../Libraries/ThirdParty"),
    ],
    testDependencies: [
        .project(target: "ThirdParty", path: "../../Libraries/ThirdParty"),
    ],
    hasTests: true
)
