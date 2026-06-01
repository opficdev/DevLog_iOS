import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogData",
    bundleId: "com.opfic.DevLog.DevLogData",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    dependencies: [
        .project(target: "DevLogDomain", path: "../DevLogDomain"),
        .project(target: "DevLogCore", path: "../DevLogCore"),
    ],
    hasTests: true
)
