import ProjectDescription

public enum DevLogPackages {
    public static let swiftLintPlugin: TargetDependency = .package(
        product: "SwiftLintBuildToolPlugin",
        type: .plugin
    )

    public static let presentationPackages: [TargetDependency] = [
        .external(name: "MarkdownUI"),
        .external(name: "OrderedCollections"),
    ]

    public static let infraPackages: [TargetDependency] = [
        .external(name: "FirebaseAnalyticsCore"),
        .external(name: "FirebaseCore"),
        .external(name: "FirebaseFunctions"),
        .external(name: "FirebaseAuth"),
        .external(name: "FirebaseMessaging"),
        .external(name: "FirebaseFirestore"),
        .external(name: "GoogleSignIn"),
        .external(name: "Nexa"),
    ]
}
