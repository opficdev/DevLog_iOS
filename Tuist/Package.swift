// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "OrderedCollections": .framework,
        "MarkdownUI": .framework,
        "SwiftLintBuildToolPlugin": .plugin,
        "FirebaseAnalyticsCore": .framework,
        "FirebaseCore": .framework,
        "FirebaseFunctions": .framework,
        "FirebaseAuth": .framework,
        "FirebaseMessaging": .framework,
        "FirebaseFirestore": .framework,
        "GoogleSignIn": .framework,
        "Nexa": .framework,
    ]
)
#endif

let package = Package(
    name: "DevLogDependencies",
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", exact: "0.62.1"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui.git", exact: "2.4.1"),
        .package(url: "https://github.com/apple/swift-collections.git", exact: "1.3.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", exact: "11.15.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", exact: "9.0.0"),
        .package(url: "https://github.com/opficdev/Nexa", exact: "1.1.0"),
    ]
)
