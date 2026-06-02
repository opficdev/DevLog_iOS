import ProjectDescription

public enum DevLogPackages {
    public static let swiftLintPackage: Package = .package(
        url: "https://github.com/realm/SwiftLint",
        .upToNextMajor(from: "0.62.1")
    )
    public static let markdownUIPackage: Package = .package(
        url: "https://github.com/gonzalezreal/swift-markdown-ui.git",
        .upToNextMajor(from: "2.4.1")
    )
    public static let swiftCollectionsPackage: Package = .package(
        url: "https://github.com/apple/swift-collections.git",
        .upToNextMajor(from: "1.3.0")
    )
    public static let firebasePackage: Package = .package(
        url: "https://github.com/firebase/firebase-ios-sdk",
        .upToNextMajor(from: "11.15.0")
    )
    public static let googleSignInPackage: Package = .package(
        url: "https://github.com/google/GoogleSignIn-iOS",
        .revision("02616ac6b469e8f00212436d2cac16e6efad7954")
    )
    public static let nexaPackage: Package = .package(
        url: "https://github.com/opficdev/Nexa",
        .upToNextMajor(from: "1.1.0")
    )

    public static let swiftLintPlugin: TargetDependency = .package(
        product: "SwiftLintBuildToolPlugin",
        type: .plugin
    )

    public static let presentationPackageDependencies: [TargetDependency] = [
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

    public static let lintOnlyPackages: [Package] = [
        swiftLintPackage,
    ]

    public static let presentationPackages: [Package] = [
        swiftLintPackage,
        markdownUIPackage,
        swiftCollectionsPackage,
    ]

    public static let infraPackages: [Package] = [
        swiftLintPackage,
        firebasePackage,
        googleSignInPackage,
        nexaPackage,
    ]
}
