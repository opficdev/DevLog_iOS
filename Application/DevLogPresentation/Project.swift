import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogPresentation",
    bundleId: "com.opfic.DevLog.DevLogPresentation",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    packages: DevLogPackages.presentationPackages,
    dependencies: [
        .project(target: "DevLogDomain", path: "../DevLogDomain"),
        .project(target: "DevLogCore", path: "../DevLogCore"),
    ] + DevLogPackages.presentationPackageDependencies,
    hasTests: true
)
