import ProjectDescription

public enum DevLogPackages {
    public static let markdownUIPackage: Package = .package(
        url: "https://github.com/gonzalezreal/swift-markdown-ui.git",
        .exact("2.4.1")
    )
    public static let swiftCollectionsPackage: Package = .package(
        url: "https://github.com/apple/swift-collections.git",
        .exact("1.3.0")
    )
    public static let composableArchitecturePackage: Package = .package(
        url: "https://github.com/pointfreeco/swift-composable-architecture",
        .exact("1.25.5")
    )
    public static let firebasePackage: Package = .package(
        url: "https://github.com/firebase/firebase-ios-sdk",
        .exact("11.15.0")
    )
    public static let googleSignInPackage: Package = .package(
        url: "https://github.com/google/GoogleSignIn-iOS",
        .revision("02616ac6b469e8f00212436d2cac16e6efad7954")
    )
    public static let nexaPackage: Package = .package(
        url: "https://github.com/opficdev/Nexa",
        .upToNextMinor(from: "1.1.1")
    )

    public static let presentationPackageDependencies: [TargetDependency] = [
        .package(product: "ComposableArchitecture"),
        .package(product: "MarkdownUI"),
        .package(product: "OrderedCollections"),
    ]

    public static let infraPackageDependencies: [TargetDependency] = [
        .package(product: "FirebaseAnalyticsCore"),
        .package(product: "FirebaseCore"),
        .package(product: "FirebaseFunctions"),
        .package(product: "FirebaseAuth"),
        .package(product: "FirebaseMessaging"),
        .package(product: "FirebaseFirestore"),
        .package(product: "GoogleSignIn"),
        .package(product: "Nexa"),
    ]

    public static let defaultPackages: [Package] = []

    public static let presentationPackages: [Package] = [
        composableArchitecturePackage,
        markdownUIPackage,
        swiftCollectionsPackage,
    ]

    public static let infraPackages: [Package] = [
        firebasePackage,
        googleSignInPackage,
        nexaPackage,
    ]
}

public enum DevLogScripts {
    public static func swiftLint(
        sourcePath: String,
        configPath: String = "../../.swiftlint.yml"
    ) -> TargetScript {
        TargetScript.pre(
        script: """
        export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

        swiftLintPath="$(command -v swiftlint || true)"
        if [ -z "$swiftLintPath" ]; then
            echo "error: SwiftLint is not installed. Run 'brew install swiftlint'."
            exit 1
        fi

        configPath="${SRCROOT}/\(configPath)"
        sourcePathName="\(sourcePath)"
        lintSourcePath="${SRCROOT}/${sourcePathName}"

        if [ "$sourcePathName" != "." ]; then
            "$swiftLintPath" lint --config "$configPath" "$lintSourcePath"
        else
            swiftFilePaths=()
            while IFS= read -r -d '' swiftFilePath; do
                swiftFilePaths+=("$swiftFilePath")
            done < <(find "$lintSourcePath" -name "*.swift" -not -path "*/Derived/*" -not -name "Project.swift" -print0)

            if [ ${#swiftFilePaths[@]} -lt 1 ]; then
                exit 0
            fi

            "$swiftLintPath" lint --config "$configPath" "${swiftFilePaths[@]}"
        fi
        """,
        name: "SwiftLint",
        inputPaths: [
            "$(SRCROOT)/\(configPath)",
            "$(SRCROOT)/\(sourcePath)",
        ],
        basedOnDependencyAnalysis: false,
        shellPath: "/bin/bash"
        )
    }
}
