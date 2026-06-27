import ProjectDescription

public enum DevLogSigning {
    public static let teamID: SettingValue = "4CPC6N38WA"
}

public extension Settings {
    static func devlog(
        versionXcconfigPath: Path? = nil,
        base: SettingsDictionary = [:],
        debug: SettingsDictionary = [:],
        staging: SettingsDictionary = [:],
        release: SettingsDictionary = [:],
        defaultSettings: DefaultSettings = .recommended
    ) -> Settings {
        var commonBase: SettingsDictionary = [
            "CURRENT_PROJECT_VERSION": "0",
            "INFOPLIST_KEY_CFBundleShortVersionString": "$(MARKETING_VERSION)",
            "INFOPLIST_KEY_CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1,2",
        ]
        commonBase.merge(base) { _, new in new }

        if let versionXcconfigPath {
            return .settings(
                base: commonBase,
                configurations: [
                    .debug(name: "Debug", settings: debug, xcconfig: versionXcconfigPath),
                    .release(name: "Staging", settings: staging, xcconfig: versionXcconfigPath),
                    .release(name: "Release", settings: release, xcconfig: versionXcconfigPath),
                ],
                defaultSettings: defaultSettings
            )
        }

        return .settings(
            base: commonBase,
            configurations: [
                .debug(name: "Debug", settings: debug),
                .release(name: "Staging", settings: staging),
                .release(name: "Release", settings: release),
            ],
            defaultSettings: defaultSettings
        )
    }

    static func devlogProject(
        versionXcconfigPath: Path? = nil,
        additionalBase: SettingsDictionary = [:]
    ) -> Settings {
        var base: SettingsDictionary = [
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "DEVELOPMENT_TEAM": DevLogSigning.teamID,
            "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
            "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
        ]
        base.merge(additionalBase) { _, new in new }
        return .devlog(versionXcconfigPath: versionXcconfigPath, base: base)
    }
}
