// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DevLogModules",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "DevLogDomain", targets: ["DevLogDomain"]),
        .library(name: "DevLogData", targets: [
            "DevLogDataCommon",
            "DevLogDataDTO",
            "DevLogDataProtocol",
            "DevLogDataMapper",
            "DevLogDataRepository"
        ]),
        .library(name: "DevLogInfra", targets: ["DevLogInfra"]),
        .library(name: "DevLogStorage", targets: ["DevLogStorage"]),
        .library(name: "DevLogPresentation", targets: ["DevLogPresentation"]),
        .library(name: "DevLogUI", targets: ["DevLogUI"]),
        .library(name: "DevLogWidgetCore", targets: [
            "DevLogWidgetCore",
            "DevLogWidgetShared"
        ]),
        .library(name: "DevLogWidgetShared", targets: ["DevLogWidgetShared"])
    ],
    targets: [
        .target(
            name: "DevLogDomain",
            path: "DevLog/Domain"
        ),
        .target(
            name: "DevLogDataCommon",
            path: "DevLog/Data/Common"
        ),
        .target(
            name: "DevLogDataDTO",
            dependencies: ["DevLogDomain"],
            path: "DevLog/Data/DTO"
        ),
        .target(
            name: "DevLogDataProtocol",
            dependencies: [
                "DevLogDomain",
                "DevLogDataDTO"
            ],
            path: "DevLog/Data/Protocol"
        ),
        .target(
            name: "DevLogDataMapper",
            dependencies: [
                "DevLogDomain",
                "DevLogDataCommon",
                "DevLogDataDTO"
            ],
            path: "DevLog/Data/Mapper"
        ),
        .target(
            name: "DevLogInfra",
            dependencies: [
                "DevLogDataCommon",
                "DevLogDataDTO",
                "DevLogDataProtocol"
            ],
            path: "DevLog/Infra"
        ),
        .target(
            name: "DevLogStorage",
            dependencies: [
                "DevLogDomain",
                "DevLogDataProtocol",
                "DevLogPresentation",
                "DevLogWidgetCore",
                "DevLogWidgetShared"
            ],
            path: "DevLog/Storage"
        ),
        .target(
            name: "DevLogDataRepository",
            dependencies: [
                "DevLogDomain",
                "DevLogDataCommon",
                "DevLogDataDTO",
                "DevLogDataProtocol",
                "DevLogDataMapper"
            ],
            path: "DevLog/Data/Repository"
        ),
        .target(
            name: "DevLogPresentation",
            dependencies: [
                "DevLogDomain",
                "DevLogDataCommon"
            ],
            path: "DevLog/Presentation"
        ),
        .target(
            name: "DevLogUI",
            dependencies: [
                "DevLogDomain",
                "DevLogPresentation"
            ],
            path: "DevLog/UI"
        ),
        .target(
            name: "DevLogWidgetCore",
            dependencies: [
                "DevLogDomain",
                "DevLogDataCommon",
                "DevLogDataProtocol",
                "DevLogPresentation",
                "DevLogWidgetShared"
            ],
            path: "DevLog/Widget"
        ),
        .target(
            name: "DevLogWidgetShared",
            path: "WidgetShared"
        )
    ]
)
