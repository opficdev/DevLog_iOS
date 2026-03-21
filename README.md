# DevLog

> 개발 기록과 Todo를 한 곳에서 관리하는 SwiftUI 기반 앱  
> 저장한 링크, 작업 메모, 마감 일정, 개인 활동 흐름을 하나의 앱 안에서 정리하는 구조

<table>
  <tr>
    <td align="center" width="25%">
      <img src="./docs/home.png">
    </td>
    <td align="center" width="25%">
      <img src="./docs/markdown.png">
    </td>
    <td align="center" width="25%">
      <img src="./docs/metadata.png">
    </td>
    <td align="center" width="25%">
      <img src="./docs/notification.png">
    </td>
  </tr>
  <tr>
    <td align="center">Home</td>
    <td align="center">Markdown</td>
    <td align="center">Todo 상세</td>
    <td align="center">푸시 알림</td>
  </tr>
</table>

## 앱 사용해보기

iOS 17 이상 환경에서 TestFlight 베타 테스트 가능

<a href="https://testflight.apple.com/join/H9hAUU8v">
  <img src="https://img.shields.io/badge/TestFlight-0D96F6?style=flat&logo=data:image/svg%2Bxml;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHZpZXdCb3g9JzAgMCAyNCAyNCc%2BPGcgZmlsbD0nI2ZmZicgdHJhbnNmb3JtPSd0cmFuc2xhdGUoMTIgMTIpJz48ZWxsaXBzZSBjeD0nMCcgY3k9Jy02JyByeD0nMy4yJyByeT0nNS40Jy8%2BPGVsbGlwc2UgY3g9JzAnIGN5PSctNicgcng9JzMuMicgcnk9JzUuNCcgdHJhbnNmb3JtPSdyb3RhdGUoMTIwKScvPjxlbGxpcHNlIGN4PScwJyBjeT0nLTYnIHJ4PSczLjInIHJ5PSc1LjQnIHRyYW5zZm9ybT0ncm90YXRlKDI0MCknLz48Y2lyY2xlIHI9JzInLz48L2c%2BPC9zdmc%2B" />
</a>

## 프로젝트 개요

개발 과정에서 해야 할 일, 참고 링크, 진행 기록이 여러 곳에 흩어지기 쉬운 문제 해결 목적  
Todo, 저장 링크, 오늘 할 일, 받은 알림, 누적 활동을 하나의 화면 흐름 안에서 함께 관리할 수 있도록 구성한 앱

- Todo 유형별 정리 및 빠른 탐색
- Markdown, 태그, 마감일, 중요 표시를 포함한 Todo 작성
- 웹 페이지 저장 및 재열람
- 오늘 기준 우선 확인 Todo 요약
- 받은 푸시 알림 확인 및 Todo 연계
- 분기별 활동 히트맵 및 주간 추이 차트 제공
- Google, GitHub, Apple 로그인 및 계정 연동

## 주요 기능

### 로그인 및 계정 관리

- Google, GitHub, Apple 로그인 지원
- 설정 화면에서 계정 연동 및 해제 관리
- 앱 내부 로그아웃 및 회원 탈퇴 흐름 제공
- Firebase Authentication 기반 사용자 세션 관리

### Home

- 작업 성격별 Todo 유형 진입점 제공
- Home에서 Todo 유형 노출 여부 및 순서 편집
- 최근 수정 Todo 별도 섹션 제공
- 저장한 웹 페이지 목록 확인 및 즉시 열람
- URL 입력 시 메타데이터 수집 후 제목과 썸네일 저장

### Todo 관리

- 8개 Todo 유형별 목록, 정렬, 완료 상태, 중요 표시 필터 지원
- Todo 목록 내 검색과 페이지네이션 기반 로드
- 스와이프 액션을 통한 중요 표시, 완료 처리, 삭제 지원
- Markdown, 태그, 마감일, 중요 표시 기반 Todo 작성 및 수정
- 상세 화면에서 생성일, 완료일, 마감일, 태그 확인

### Today

- 남은 일, 집중 Todo, 지연 Todo, 7일 내 마감 Todo 요약 카드 제공
- 집중할 일, 지난 마감, 나중 일정, 일정 미정 등 기한 기준 섹션 분류
- 보기 범위와 중요 표시 조건 기반 빠른 필터링
- 항목별 스와이프 액션을 통한 중요 표시 및 완료 처리

### 알림

- 받은 푸시 알림 목록 확인
- 정렬, 기간, 읽지 않음 기준 필터링
- 알림 선택 시 연결된 Todo 상세 확인 및 읽음 처리
- 페이지네이션 및 실시간 동기화 기반 알림 목록 갱신
- 사용자 설정 시각 기준으로 다음 날 마감 Todo 리마인드 푸시 발송

### 검색

- Home 화면 검색 버튼을 통한 통합 검색 진입
- Todo와 저장한 웹 페이지 통합 검색
- 디바운스 기반 검색 처리
- 최근 검색어 저장, 개별 삭제, 전체 삭제 지원

### 프로필 및 설정

- 상태 메시지 직접 수정
- 분기 이동 및 직접 선택, 생성/완료 활동 필터 기반 히트맵과 주간 추이 차트 제공
- 테마 변경, 푸시 알림 시간 설정, 캐시 정리 기능 제공
- 설정 화면에서 앱 버전, 개인정보 처리방침, 베타 테스트 링크 확인

---

## 기술 스택

| 구분 | 스택 |
| --- | --- |
| Deployment Target | iOS 17+ |
| Architecture | MVVM, MVI-inspired state flow, Clean Architecture, Repository Pattern, DI Container |
| UI | SwiftUI, Charts, MarkdownUI |
| State & Async | Observable, Combine, async/await |
| Backend | FirebaseAuth, FirebaseFirestore, Firebase Cloud Functions, FirebaseMessaging |
| Apple Frameworks | AuthenticationServices, UserNotifications, LinkPresentation, Network |
| Utility | GoogleSignIn, OrderedCollections |
| Tooling | Xcode, Swift Package Manager, SwiftLint, Fastlane |

## 아키텍처

MVVM을 기반으로 하되, ViewModel 상태 관리에는 MVI 형태의 단방향 흐름을 차용한 구조  
화면, 상태, 비즈니스 로직, 외부 의존성 분리를 위한 `MVVM + Clean Architecture` 기반 구성

<table>
  <tr>
    <td align="center" width="50%">
      <img alt="architecture" src="./docs/architecture.png" />
    </td>
    <td align="center" width="50%">
      <img alt="Store" src="./docs/store-protocol.png" />
    </td>
  </tr>
  <tr>
    <td align="center">앱 계층</td>
    <td align="center">Store 프로토콜</td>
  </tr>
</table>

## 프로젝트 구조

```text
SwiftUI_DevLog/
├── DevLog/
│   ├── App/                  # 앱 진입점, DI, Assembler, Root 구성
│   ├── Data/                 # DTO, Mapper, Repository 구현
│   ├── Domain/               # Entity, Protocol, UseCase
│   ├── Infra/                # Firebase 및 시스템 서비스
│   ├── Presentation/         # ViewModel, 화면용 구조체와 프로토콜
│   ├── Storage/              # 로컬 저장소 및 사용자 설정 영속성 처리
│   ├── UI/                   # SwiftUI 화면
│   └── Resource/             # plist, asset, 이미지 리소스
├── Firebase/
│   └── functions/            # 인증 보조, 푸시 발송, 정리 작업용 Cloud Functions
└── README.md
```
