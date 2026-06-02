import ProjectDescription

let tuist = Config(
    project: .tuist(
        generationOptions: .options(
            clonedSourcePackagesDirPath: .relativeToRoot(".spm"),
            enforceExplicitDependencies: true,
            defaultConfiguration: "Debug"
        )
    )
)
