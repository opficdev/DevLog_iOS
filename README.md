# DevLog

개발 기록과 Todo를 한 곳에서 관리하는 SwiftUI 기반 앱  
저장한 링크, 작업 메모, 마감 일정, 개인 활동 흐름을 하나의 앱 안에서 정리하는 구조

> 대표 이미지 및 기능 스크린샷 추후 추가 예정

---

## 프로젝트 개요

개발 과정에서 해야 할 일, 참고 링크, 진행 기록이 여러 곳에 흩어지기 쉬운 문제 해결 목적  
Todo, 저장 링크, 오늘 할 일, 누적 활동을 하나의 화면 흐름 안에서 함께 관리할 수 있도록 구성한 앱

- Todo 유형별 정리 및 빠른 탐색
- 웹 페이지 저장 및 재열람
- 오늘 기준 우선 확인 Todo 요약
- 분기별 활동 히트맵 및 주간 추이 차트 제공
- Google, GitHub, Apple 로그인 및 계정 연동

### 이 프로젝트에서 집중한 고민

무엇을 사용했는가보다 어떤 문제를 어떤 기준으로 해결했는가에 대한 대표 사례 정리

| 분야 | 대표 문서 | 다룬 고민 | 링크 |
| --- | --- | --- | --- |
| UI | TodoListView 헤더 트러블슈팅 - 내비게이션바 UI | iOS 17과 iOS 18 이상의 서로 다른 스크롤 및 내비게이션바 동작을 어떻게 하나의 헤더 경험으로 정리할지에 대한 고민 | [위키](https://github.com/opficdev/SwiftUI_DevLog/wiki/TodoListView-헤더-트러블슈팅-%E2%80%90-네비게이션바-UI) |
| 상태 관리 | iOS 17 이하에서 모달의 isPresented 관리하기 | MVI 형태의 상태 흐름 안에서 `sheet`와 `fullScreenCover`가 충돌하지 않도록 어떤 타이밍으로 상태를 분리할지에 대한 고민 | [위키](https://github.com/opficdev/SwiftUI_DevLog/wiki/iOS-17-이하에서-MVI-패턴을-적용했을-때-동시에-모달을-처리하기) |
| 검색 UX | iOS 17 `.searchable` 포커싱 이슈 해결기 | OS 버전 차이 속에서 자동 포커싱 경험과 안정성 사이를 어떤 방식으로 절충할지에 대한 고민 | [위키](https://github.com/opficdev/SwiftUI_DevLog/wiki/iOS-17-.searchable-포커싱-이슈-해결기) |
| 데이터 처리 | LPMetadataProvider로 웹페이지 썸네일 가져오기 | 캐시 삭제 이후에도 링크 썸네일을 복구하면서 UI 갱신 흐름은 단순하게 유지할 방법에 대한 고민 | [위키](https://github.com/opficdev/SwiftUI_DevLog/wiki/LPMetadataProvider로-웹페이지-썸네일-가져오기) |
| 알림 UX | PushNotificationView의 푸시 알람 기록 UNDO 과정 | 삭제 대기 상태와 페이지네이션 fetch가 충돌할 때 UNDO 경험을 어떻게 일관되게 유지할지에 대한 고민 | [위키](https://github.com/opficdev/SwiftUI_DevLog/wiki/PushNotificationView의-푸시-알람-기록-UNDO-과정%E2%80%90V2) |
| 백엔드 | Todo 리마인더 구현 트러블슈팅 | 사용자 시간대, 중복 방지, 스키마 정합성을 만족하는 리마인더 배치 구조를 어떻게 설계할지에 대한 고민 | [위키](https://github.com/opficdev/SwiftUI_DevLog/wiki/Todo-리마인더-구현-트러블슈팅) |

세부 구현 과정과 트레이드오프는 위키 문서에 별도 정리

---

## 주요 기능

### 로그인 및 계정 관리

- Google, GitHub, Apple 로그인 지원
- 설정 화면에서 계정 연동 및 해제 관리
- 앱 내부 로그아웃 및 회원 탈퇴 흐름 제공
- Firebase Authentication 기반 사용자 세션 관리

### Home

- 작업 성격별 Todo 유형 진입점 제공
- 최근 수정 Todo 별도 섹션 제공
- 저장한 웹 페이지 목록 확인 및 즉시 열람
- URL 입력 시 메타데이터 수집 후 제목과 썸네일 저장

### Today

- 남은 일, 집중 Todo, 지연 Todo, 7일 내 마감 Todo 요약 카드 제공
- 보기 범위와 중요 표시 조건 기반 빠른 필터링
- 항목별 스와이프 액션을 통한 중요 표시 및 완료 처리

### 검색 및 기록 작성

- Todo와 저장한 웹 페이지 통합 검색
- 디바운스 기반 검색 처리
- 최근 검색어 저장 및 재사용
- Markdown 기반 Todo 작성 및 미리보기 지원

### 프로필 및 설정

- 상태 메시지 직접 수정
- 분기별 활동 히트맵과 주간 추이 차트를 통한 생성 및 완료 흐름 확인
- 테마 변경, 푸시 알림 설정, 캐시 정리 기능 제공
- 설정 화면에서 앱 버전과 개인정보 처리방침 링크 확인

---

## 기술 스택

| 구분 | 스택 |
| --- | --- |
| Architecture | <img src="https://img.shields.io/badge/MVVM-0A84FF?style=flat" alt="MVVM" /> <img src="https://img.shields.io/badge/MVI--inspired_State_Flow-8E44AD?style=flat" alt="MVI-inspired state flow" /> <img src="https://img.shields.io/badge/Clean_Architecture-34495E?style=flat" alt="Clean Architecture" /> <img src="https://img.shields.io/badge/Repository_Pattern-16A085?style=flat" alt="Repository Pattern" /> <img src="https://img.shields.io/badge/DI_Container-E67E22?style=flat" alt="DI Container" /> |
| UI | <img src="https://img.shields.io/badge/SwiftUI-0D96F6?style=flat&logo=swift&logoColor=white" alt="SwiftUI" /> <img src="https://img.shields.io/badge/Charts-30B0C7?style=flat&logo=apple&logoColor=white" alt="Charts" /> <img src="https://img.shields.io/badge/MarkdownUI-000000?style=flat&logo=markdown&logoColor=white" alt="MarkdownUI" /> |
| State & Async | <img src="https://img.shields.io/badge/%40Observable-F05138?style=flat&logo=swift&logoColor=white" alt="@Observable" /> <img src="https://img.shields.io/badge/Combine-1F6FEB?style=flat&logo=apple&logoColor=white" alt="Combine" /> <img src="https://img.shields.io/badge/async%2Fawait-1ABC9C?style=flat&logo=swift&logoColor=white" alt="async/await" /> |
| Backend | <img src="https://img.shields.io/badge/FirebaseAuth-FFCA28?style=flat&logo=firebase&logoColor=black" alt="FirebaseAuth" /> <img src="https://img.shields.io/badge/Firestore-FFCA28?style=flat&logo=firebase&logoColor=black" alt="Firestore" /> <img src="https://img.shields.io/badge/Cloud_Functions-FFCA28?style=flat&logo=firebase&logoColor=black" alt="Cloud Functions" /> <img src="https://img.shields.io/badge/Firebase_Messaging-FFCA28?style=flat&logo=firebase&logoColor=black" alt="Firebase Messaging" /> |
| Apple Frameworks | <img src="https://img.shields.io/badge/AuthenticationServices-000000?style=flat&logo=apple&logoColor=white" alt="AuthenticationServices" /> <img src="https://img.shields.io/badge/UserNotifications-5AC8FA?style=flat&logo=apple&logoColor=white" alt="UserNotifications" /> <img src="https://img.shields.io/badge/LinkPresentation-5856D6?style=flat&logo=apple&logoColor=white" alt="LinkPresentation" /> <img src="https://img.shields.io/badge/Network-34C759?style=flat&logo=apple&logoColor=white" alt="Network" /> |
| Utility | <img src="https://img.shields.io/badge/GoogleSignIn-4285F4?style=flat&logo=google&logoColor=white" alt="GoogleSignIn" /> <img src="https://img.shields.io/badge/OrderedCollections-F05138?style=flat&logo=swift&logoColor=white" alt="OrderedCollections" /> |
| Tooling | <img src="https://img.shields.io/badge/Xcode-147EFB?style=flat&logo=xcode&logoColor=white" alt="Xcode" /> <img src="https://img.shields.io/badge/Swift_Package_Manager-F05138?style=flat&logo=swift&logoColor=white" alt="Swift Package Manager" /> <img src="https://img.shields.io/badge/SwiftLint-8E44AD?style=flat&logo=swift&logoColor=white" alt="SwiftLint" /> |

---

## 아키텍처

MVVM을 기반으로 하되, ViewModel 상태 관리에는 MVI 형태의 단방향 흐름을 차용한 구조  
화면, 상태, 비즈니스 로직, 외부 의존성 분리를 위한 `MVVM + Clean Architecture` 기반 구성

```text
UI
-> Presentation(ViewModel)
-> Domain(UseCase)
-> Data(Repository)
-> Infra(Service / Firebase / UserDefaults / Network)
```

- `UI`: SwiftUI 화면과 사용자 인터랙션 담당
- `Presentation`: `@Observable` 기반 ViewModel 상태 및 액션 관리
- `State Flow`: `State -> Action -> reduce -> SideEffect -> state update` 흐름 적용
- `Domain`: UseCase 중심 비즈니스 규칙 분리
- `Data`: Repository를 통한 Domain과 Infra 연결
- `Infra`: Firebase, 네트워크 상태 감지, 메타데이터 조회 등 외부 의존성 캡슐화
- 앱 시작 시 Assembler와 DI Container를 통한 의존성 등록

---

## 프로젝트 구조

```text
SwiftUI_DevLog/
├── DevLog/
│   ├── App/                  # 앱 진입점, DI, Assembler, Root 구성
│   ├── Data/                 # DTO, Mapper, Repository 구현
│   ├── Domain/               # Entity, Protocol, UseCase
│   ├── Infra/                # Firebase 및 시스템 서비스
│   ├── Presentation/         # ViewModel, 화면용 구조체와 프로토콜
│   ├── Storage/              # 로컬 저장소 및 영속성 처리
│   ├── UI/                   # SwiftUI 화면
│   └── Resource/             # plist, asset, 이미지 리소스
├── Firebase/
│   └── functions/            # Cloud Functions 소스
└── README.md
```

`UI`는 `Home`, `Today`, `Search`, `Profile`, `Setting`, `Login` 중심 구성  
각 화면은 대응되는 ViewModel과 UseCase 주입 기반 동작
