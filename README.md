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
| Architecture | MVVM, MVI-inspired state flow, Clean Architecture, Repository Pattern, DI Container |
| UI | SwiftUI, Charts, MarkdownUI |
| State & Async | Observable, Combine, async/await |
| Backend | FirebaseAuth, FirebaseFirestore, FirebaseFunctions, FirebaseMessaging |
| Apple Frameworks | AuthenticationServices, UserNotifications, LinkPresentation, Network |
| Utility | GoogleSignIn, OrderedCollections |
| Tooling | Xcode, Swift Package Manager, SwiftLint |

---

## 아키텍처

MVVM을 기반으로 하되, ViewModel 상태 관리에는 MVI 형태의 단방향 흐름을 차용한 구조  
화면, 상태, 비즈니스 로직, 외부 의존성 분리를 위한 `MVVM + Clean Architecture` 기반 구성

<img alt="architecture" src="https://github.com/user-attachments/assets/5aa15b55-9aff-40b5-9b3d-9d2e5bd7f94b" />

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
