# CollectionUI 제거 Spec

- Source: https://github.com/opficdev/DevLog_iOS/issues/835
- Approved Designer Result: 2026-08-27 사용자 승인
- User approval: `ㄱㄱ`

## Constraints

- `TodoListView`의 현재 SwiftUI `List` 구성과 `safeAreaInset`, `onScrollOffsetChange`, `.navigationTitle`, `.refreshable`, 로딩, 빈 목록, 검색, 상세 이동, 페이지네이션, 스와이프 동작을 변경하지 않는다.
- `TodoItemRow`와 `TagList(tags, lineLimit: 1)` 계약을 유지한다.
- `Application/Presentation/Project.swift`와 PresentationShared는 이미 CollectionUI 의존성과 import가 없으므로 변경하지 않는다.
- 새 UIKit 목록 renderer, Domain, Data, Firebase, 관련 이슈 #815, #816, #817, #834는 변경하지 않는다.
- 생성된 `.xcodeproj`, `.xcworkspace`, `DerivedData`, `Package.resolved`는 추적하지 않는다.

## Alternatives and decision

- `71b5ac1b7` 전체 되돌리기는 CollectionUI와 무관한 변경을 함께 되돌리므로 사용하지 않는다.
- `Libraries/CollectionUI`만 삭제하면 Workspace와 CI의 끊어진 참조가 남으므로 사용하지 않는다.
- 현재 SwiftUI `TodoListView`와 Presentation 경계는 그대로 두고 Workspace, CI, 구조도 연결을 제거한 뒤 고립된 `Libraries/CollectionUI`를 삭제한다.

## Changed boundaries

- Workspace에서 `Libraries/CollectionUI` 프로젝트와 `CollectionUITests`를 제거한다.
- CI Libraries 묶음은 `MarkdownRenderer`만 유지하고 `CollectionUITests` 전용 테스트 경로 분기를 제거한다.
- Todo 목록의 렌더링과 스크롤 계약은 PresentationShared의 SwiftUI `List`가 계속 소유한다.
- `docs/graph.png`에서 제거된 `CollectionUI` 노드를 없앤다.

## Acceptance criteria

- [ ] `Libraries/CollectionUI`의 추적 파일과 생성물이 모두 제거된다.
- [ ] `Workspace.swift`에 `Libraries/CollectionUI` 등록이 없다.
- [ ] `.github/workflows/ci.yml`에 `CollectionUITests` scheme과 `Libraries/CollectionUI/Tests` 분기가 없다.
- [ ] Spec을 제외한 추적 파일 전체에서 `CollectionUI`, `CollectionUITests`, `TodoListCollectionView`, `TodoListCollectionCell`, `CollectionRenderingSnapshot` 참조가 없다.
- [ ] `docs/graph.png`에 `CollectionUI` 노드가 없고 나머지 모듈 관계가 유지된다.
- [ ] `Application/Presentation/Project.swift`에 CollectionUI 의존성이 없으며 불필요한 변경이 없다.
- [ ] `TodoListView.swift`의 기존 SwiftUI `List`와 화면 계약이 유지된다.
- [ ] `TodoItemRow`와 `TagList(tags, lineLimit: 1)` 계약이 유지된다.
- [ ] Domain, Data, Firebase와 관련 이슈 #815, #816, #817, #834에 변경이 없다.
- [ ] `tuist generate --no-open`과 `App` scheme build가 성공하고 생성물 변경이 추적되지 않는다.

## Verification

- Command: `git grep -n -E 'CollectionUI|CollectionUITests|TodoListCollection(View|Cell)|CollectionRenderingSnapshot' -- ':!.agents/specs/835-collection-ui-removal.md'`
- Evidence: 결과 없음
- Command: `git ls-files Libraries/CollectionUI`
- Evidence: 결과 없음
- Command: `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml", aliases: true)'`
- Evidence: 정상 종료
- Command: `mise exec -- tuist generate --no-open`
- Evidence: 정상 종료
- Command: `xcodebuild -workspace DevLog.xcworkspace -scheme App -configuration Debug -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation -skipMacroValidation -showBuildTimingSummary build`
- Evidence: 정상 종료
- Command: `git diff --check`
- Evidence: 정상 종료
- 실기기 헤더와 `navigationTitle` 동작은 현재 실행 권한으로 검증하지 않는다.

## Minimum commit units

1. `chore: CollectionUI 빌드 그래프와 CI 연결 제거`
   - `.agents/specs/835-collection-ui-removal.md`, `Workspace.swift`, `.github/workflows/ci.yml`, `docs/graph.png`
2. `refactor: CollectionUI 라이브러리 제거`
   - `Libraries/CollectionUI/**`

## Execution constraints

- app or Simulator execution: 금지
- External writes: 로컬 커밋만 허용
- CI or PR actions: 금지
