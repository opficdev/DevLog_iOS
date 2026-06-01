import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogDomain",
    bundleId: "com.opfic.DevLog.DevLogDomain",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    dependencies: [
        .project(target: "DevLogCore", path: "../DevLogCore"),
    ],
    hasTests: true
)
