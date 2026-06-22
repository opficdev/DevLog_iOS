# DevLog Tuist Migration Design

## 목표

기존 `DevLog_iOS`의 모듈 경계와 의존성 방향을 유지한 채, 수동 관리 중인 Xcode 프로젝트/워크스페이스를 Tuist 기반 생성 구조로 전환한다.

## 버전 선택

- 선택 버전: `Tuist 4.194.4`
- 설치 방식: `mise` 기반 프로젝트 고정

### 선정 근거

- Tuist 공식 설치 문서는 팀 단위의 결정적 버전 관리를 위해 `mise` 사용을 권장한다.
- 2026년 CLI 릴리스 분포를 확인한 결과, `4.195.x`가 가장 최신이지만 `4.195.11`에는 공개 이슈 2건이 즉시 연결된다.
- 동일 조사 기준에서 `4.194.4`, `4.193.4`, `4.192.4`, `4.191.8`은 정확한 패치 버전 문자열 기준 공개 이슈 연결이 보이지 않았다.
- 그중 `4.194.4`는 가장 최신에 가까우면서 `4.195.11` 대비 공개 회귀 신호가 적은 버전이다.

### 해석 주의

- “가장 버그가 없는 버전”은 절대적으로 증명할 수 없다.
- 본 작업에서는 `공개 GitHub 이슈 검색`, `릴리스 최신성`, `패치 수렴 정도`를 합친 근거 기반 추정으로 선택한다.

## 목표 구조

Tuist 표준 구조를 사용한다.

- 루트
  - `Tuist.swift`
  - `Workspace.swift`
  - `Tuist/Package.swift`
  - `Tuist/ProjectDescriptionHelpers/*`
- 모듈별
  - `Application/DevLogApp/Project.swift`
  - `Application/DevLogCore/Project.swift`
  - `Application/DevLogData/Project.swift`
  - `Application/DevLogDomain/Project.swift`
  - `Application/DevLogInfra/Project.swift`
  - `Application/DevLogPersistence/Project.swift`
  - `Application/DevLogPresentation/Project.swift`
  - `Widget/DevLogWidgetCore/Project.swift`
  - `Widget/DevLogWidgetExtension/Project.swift`

## 모듈 구조 결정

### 유지할 논리 모듈

- App: `DevLog`
- App test bundle: `DevLogAppTests`
- Frameworks: `DevLogCore`, `DevLogDomain`, `DevLogData`, `DevLogInfra`, `DevLogPersistence`, `DevLogPresentation`, `DevLogWidgetCore`
- Framework test bundles: 각 모듈의 `*Tests`
- Widget extension: `DevLogWidgetExtension`

### Tuist 표준에 맞춘 구조 변경

- 기존에는 `DevLogWidgetExtension` 타깃이 `Application/DevLogApp.xcodeproj` 내부에 있었다.
- 전환 후에는 `Widget/DevLogWidgetExtension/Project.swift`를 만들어 위젯 확장을 별도 프로젝트로 분리한다.
- 이는 Xcode 프로젝트 배치만 표준화하는 것이며, 논리 모듈과 의존성 방향은 유지한다.

## 의존성 유지 기준

### 내부 의존성

- `DevLogDomain` -> `DevLogCore`
- `DevLogData` -> `DevLogDomain`, `DevLogCore`
- `DevLogInfra` -> `DevLogData`, `DevLogDomain`, `DevLogCore`
- `DevLogPersistence` -> `DevLogData`, `DevLogCore`, `DevLogWidgetCore`
- `DevLogPresentation` -> `DevLogDomain`, `DevLogCore`
- `DevLogWidgetCore` -> `DevLogCore`
- `DevLog` -> `DevLogPresentation`, `DevLogPersistence`, `DevLogInfra`, `DevLogData`, `DevLogDomain`, `DevLogCore`, `DevLogWidgetCore`
- `DevLogWidgetExtension` -> `DevLogWidgetCore`

### 외부 패키지

- `DevLogPresentation`
  - `MarkdownUI`
  - `OrderedCollections`
- `DevLogInfra`
  - `FirebaseAnalyticsCore`
  - `FirebaseCore`
  - `FirebaseFunctions`
  - `FirebaseAuth`
  - `FirebaseMessaging`
  - `FirebaseFirestore`
  - `GoogleSignIn`
  - `Nexa`
- 전 모듈 공통
  - `SwiftLintBuildToolPlugin`

## 설정 유지 기준

- 배포 타깃: 기본 `iOS 17`
- 공통 마케팅 버전: `Application/Shared/Version.xcconfig` 유지
- App bundle id: `opfic.DevLog`
- Widget bundle id: `opfic.DevLog.DevLogWidget`
- 각 프레임워크/테스트 번들 식별자는 현재 값 유지
- App entitlements: `Application/DevLogApp/Sources/Resource/DevLog.entitlements`
- Widget entitlements: `Widget/DevLogWidgetExtension/Resource/DevLogWidget.entitlements`
- App/Widget Info.plist와 리소스 경로 유지
- App tests는 기존과 동일하게 `DevLog`를 host target으로 유지

## 생성 결과 목표

- 생성된 루트 워크스페이스 이름은 계속 `DevLog.xcworkspace`
- 주요 CI 빌드 기준은 계속 `workspace=DevLog.xcworkspace`, `scheme=DevLog`
- 기존 수동 `project.pbxproj` 수정 흐름을 Tuist manifest 수정 흐름으로 대체

## 커밋 분할 원칙

### 1단계

- Tuist 버전 고정
- 루트 매니페스트
- 공통 helper / 패키지 선언
- 설계 문서와 계획 문서

### 2단계

- 모듈별 `Project.swift`
- App / WidgetExtension 분리
- 테스트 타깃 / 의존성 / 리소스 / 빌드 설정 이관

### 3단계

- `tuist install`
- `tuist generate`
- 생성 산출물 반영
- 워크스페이스/스킴/빌드 검증

## 검증 기준

- `tuist install` 성공
- `tuist generate` 성공
- 생성된 `DevLog.xcworkspace`에 `DevLog` 스킴 존재
- iOS Simulator 대상 `DevLog` 빌드 성공
- 의존성 방향이 기존과 동일함을 manifest와 생성 결과에서 확인
