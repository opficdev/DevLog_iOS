import ProjectDescription

public enum DevLogSigning {
    public static let teamID = "4CPC6N38WA"
}

public extension Settings {
    static func devlog(
        versionXcconfigPath: Path? = nil,
        base: SettingsDictionary = [:],
        debug: SettingsDictionary = [:],
        release: SettingsDictionary = [:],
        defaultSettings: DefaultSettings = .recommended
    ) -> Settings {
        var commonBase: SettingsDictionary = [
            "CURRENT_PROJECT_VERSION": "1",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1,2",
        ]
        commonBase.merge(base) { _, new in new }

        if let versionXcconfigPath {
            return .settings(
                base: commonBase,
                configurations: [
                    .debug(name: "Debug", settings: debug, xcconfig: versionXcconfigPath),
                    .release(name: "Release", settings: release, xcconfig: versionXcconfigPath),
                ],
                defaultSettings: defaultSettings
            )
        }

        return .settings(
            base: commonBase,
            configurations: [
                .debug(name: "Debug", settings: debug),
                .release(name: "Release", settings: release),
            ],
            defaultSettings: defaultSettings
        )
    }
}
