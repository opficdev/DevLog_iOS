# MarkdownRenderer

Todo Markdown을 앱에 포함할 HTML, JavaScript, CSS로 변환하는 도구입니다.
renderer source와 build script, 테스트는 TypeScript로 작성합니다.

## 환경

- Node.js `24.18.0`
- npm `11.16.0`

## 설치

```bash
npm ci
```

## 테스트

```bash
npm test
```

## 타입 검사

```bash
npm run typecheck
```

## bundle 생성

```bash
npm run build
```

Xcode 빌드 전에 bundle을 생성해야 합니다.
생성 결과는 다음 경로에 저장합니다.

```text
Application/Presentation/PresentationShared/Resources/MarkdownRenderer/
```

컴파일된 `renderer.js`, `index.html`, `renderer.css`는 앱 자원으로 추적합니다.
CI에서는 bundle을 다시 생성하고 추적된 파일과 일치하는지 검사합니다.

의존성 버전은 `package.json`과 `package-lock.json`으로 고정합니다.
포함된 패키지는 모두 각 패키지의 라이선스 조건을 따릅니다.
