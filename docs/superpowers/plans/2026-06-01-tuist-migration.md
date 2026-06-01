# Tuist Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** DevLog의 기존 모듈 의존성 구조를 유지한 채 Tuist 표준 매니페스트와 생성 워크플로로 전환

**Architecture:** 루트 workspace와 모듈별 project manifest를 분리하고, 공통 설정과 패키지 선언은 `Tuist/ProjectDescriptionHelpers`와 `Tuist/Package.swift`로 중앙화한다. 기존 Xcode 프로젝트의 논리적 타깃 경계는 유지하되, `WidgetExtension`은 Tuist 표준에 맞게 독립 프로젝트로 분리한다.

**Tech Stack:** Tuist 4.194.4, Xcode workspace, SwiftPM, SwiftLint build tool plugin

---

### Task 1: Tuist 기반 골격과 버전 고정 추가

**Files:**
- Create: `docs/superpowers/specs/2026-06-01-tuist-migration-design.md`
- Create: `docs/superpowers/plans/2026-06-01-tuist-migration.md`
- Create: `.mise.toml`
- Create: `Tuist.swift`
- Create: `Workspace.swift`
- Create: `Tuist/Package.swift`
- Create: `Tuist/ProjectDescriptionHelpers/Project+Templates.swift`
- Create: `Tuist/ProjectDescriptionHelpers/Project+Settings.swift`
- Create: `Tuist/ProjectDescriptionHelpers/Project+Packages.swift`

- [ ] **Step 1: Tuist 버전 고정 파일을 추가**

```toml
[tools]
tuist = "4.194.4"
```

- [ ] **Step 2: 루트 Tuist 설정과 workspace manifest를 추가**

```swift
import ProjectDescription

let tuist = Config(
    project: .tuist(
        generationOptions: .options()
    )
)
```

```swift
import ProjectDescription

let workspace = Workspace(
    name: "DevLog",
    projects: [
        "Application/DevLogApp",
        "Application/DevLogCore",
        "Application/DevLogData",
        "Application/DevLogDomain",
        "Application/DevLogInfra",
        "Application/DevLogPersistence",
        "Application/DevLogPresentation",
        "Widget/DevLogWidgetCore",
        "Widget/DevLogWidgetExtension",
    ]
)
```

- [ ] **Step 3: 외부 패키지와 공통 helper 뼈대를 추가**

```swift
// Tuist/Package.swift
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
```

- [ ] **Step 4: Task 1 변경사항 커밋**

Run:

```bash
git add docs/superpowers/specs/2026-06-01-tuist-migration-design.md docs/superpowers/plans/2026-06-01-tuist-migration.md .mise.toml Tuist.swift Workspace.swift Tuist
git commit -m "chore: tuist 전환 기반 추가"
```

Expected: 문서와 Tuist 골격만 포함된 첫 커밋 생성

### Task 2: 모듈별 Project.swift와 의존성 이관

**Files:**
- Create: `Application/DevLogApp/Project.swift`
- Create: `Application/DevLogCore/Project.swift`
- Create: `Application/DevLogData/Project.swift`
- Create: `Application/DevLogDomain/Project.swift`
- Create: `Application/DevLogInfra/Project.swift`
- Create: `Application/DevLogPersistence/Project.swift`
- Create: `Application/DevLogPresentation/Project.swift`
- Create: `Widget/DevLogWidgetCore/Project.swift`
- Create: `Widget/DevLogWidgetExtension/Project.swift`

- [ ] **Step 1: 공통 framework/test 템플릿을 helper에 구현**

```swift
import ProjectDescription

public extension Project {
    static func devlogFramework(
        name: String,
        dependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = []
    ) -> Project {
        Project(
            name: name,
            targets: [
                .target(
                    name: name,
                    destinations: .iOS,
                    product: .framework,
                    bundleId: "com.opfic.DevLog.\(name)",
                    deploymentTargets: .iOS("17.0"),
                    infoPlist: .default,
                    sources: ["Sources/**"],
                    dependencies: dependencies + [.package(product: "SwiftLintBuildToolPlugin", type: .plugin)],
                    settings: .devlogFrameworkSettings
                ),
                .testTarget(
                    name: "\(name)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    bundleId: "com.opfic.DevLog.\(name)Tests",
                    infoPlist: .default,
                    sources: ["Tests/**"],
                    dependencies: [.target(name: name)] + testDependencies,
                    settings: .devlogTestSettings(testTargetName: name)
                ),
            ]
        )
    }
}
```

- [ ] **Step 2: App, WidgetExtension, 개별 모듈 manifest를 구현**

```swift
// 예시: Application/DevLogPresentation/Project.swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "DevLogPresentation",
    dependencies: [
        .project(target: "DevLogDomain", path: "../DevLogDomain"),
        .project(target: "DevLogCore", path: "../DevLogCore"),
        .external(name: "MarkdownUI"),
        .external(name: "OrderedCollections"),
    ]
)
```

```swift
// 예시: Widget/DevLogWidgetExtension/Project.swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "DevLogWidgetExtension",
    targets: [
        .target(
            name: "DevLogWidgetExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "opfic.DevLog.DevLogWidget",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .file(path: "Resource/Info.plist"),
            sources: ["**/*.swift"],
            resources: ["Resource/**"],
            entitlements: .file(path: "Resource/DevLogWidget.entitlements"),
            dependencies: [
                .project(target: "DevLogWidgetCore", path: "../DevLogWidgetCore"),
            ],
            settings: .devlogWidgetSettings
        ),
    ]
)
```

- [ ] **Step 3: App test host / resource / bundle id 설정을 기존 값으로 맞춘다**

Run:

```bash
rg -n "TEST_HOST|BUNDLE_LOADER|PRODUCT_BUNDLE_IDENTIFIER|INFOPLIST_FILE|CODE_SIGN_ENTITLEMENTS" Application/DevLogApp/DevLogApp.xcodeproj/project.pbxproj
```

Expected: App 테스트와 Widget/App 리소스 경로를 manifest 설정으로 모두 옮길 수 있을 만큼 기존 값이 반영됨

- [ ] **Step 4: Task 2 변경사항 커밋**

Run:

```bash
git add Application/DevLogApp/Project.swift Application/DevLogCore/Project.swift Application/DevLogData/Project.swift Application/DevLogDomain/Project.swift Application/DevLogInfra/Project.swift Application/DevLogPersistence/Project.swift Application/DevLogPresentation/Project.swift Widget/DevLogWidgetCore/Project.swift Widget/DevLogWidgetExtension/Project.swift Tuist/ProjectDescriptionHelpers
git commit -m "feat: tuist 모듈 매니페스트 구성"
```

Expected: 각 모듈 manifest와 helper만 포함된 두 번째 커밋 생성

### Task 3: 설치, 생성, 교체, 검증

**Files:**
- Modify: `DevLog.xcworkspace/**`
- Modify: `Application/*/*.xcodeproj/**`
- Modify: `Widget/*/*.xcodeproj/**`
- Modify: `DevLog.xcworkspace/xcshareddata/swiftpm/Package.resolved`

- [ ] **Step 1: Tuist 4.194.4 설치와 의존성 설치**

Run:

```bash
brew install mise
mise install tuist@4.194.4
mise use -p tuist@4.194.4
tuist version
tuist install
```

Expected: `tuist version`이 `4.194.4`를 출력하고, 패키지 설치가 완료됨

- [ ] **Step 2: 프로젝트를 생성하고 산출물을 교체**

Run:

```bash
tuist generate
```

Expected: `DevLog.xcworkspace`와 각 모듈 `.xcodeproj`가 Tuist 생성 산출물로 갱신됨

- [ ] **Step 3: 스킴과 빌드를 검증**

Run:

```bash
xcodebuild -workspace DevLog.xcworkspace -list
xcodebuild -workspace DevLog.xcworkspace -scheme DevLog -resolvePackageDependencies
```

Expected: `DevLog` 스킴이 존재하고 패키지 해석이 성공함

- [ ] **Step 4: iOS Simulator 빌드 검증**

Run:

```bash
xcodebuild -workspace DevLog.xcworkspace -scheme DevLog -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16" build
```

Expected: simulator build 성공

- [ ] **Step 5: Task 3 변경사항 커밋**

Run:

```bash
git add DevLog.xcworkspace Application Widget .mise.toml Tuist.swift Workspace.swift Tuist
git commit -m "refactor: tuist 생성 구조로 전환"
```

Expected: 생성 산출물과 최종 워크플로가 반영된 세 번째 커밋 생성
