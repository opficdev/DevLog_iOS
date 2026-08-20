import ProjectDescription

public enum DevLogPackages {
    public static let defaultPackages: [Package] = []
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
