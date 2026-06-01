import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogInfra",
    bundleId: "com.opfic.DevLog.DevLogInfra",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    dependencies: [
        .project(target: "DevLogData", path: "../DevLogData"),
        .project(target: "DevLogDomain", path: "../DevLogDomain"),
        .project(target: "DevLogCore", path: "../DevLogCore"),
    ] + DevLogPackages.infraPackages,
    hasTests: true
)
