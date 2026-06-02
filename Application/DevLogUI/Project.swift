import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogUI",
    bundleId: "com.opfic.DevLog.DevLogUI",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    packages: DevLogPackages.presentationPackages,
    dependencies: [
        .project(target: "DevLogCore", path: "../DevLogCore"),
        .project(target: "DevLogPresentation", path: "../DevLogPresentation"),
    ] + DevLogPackages.presentationPackageDependencies,
    hasTests: false
)
