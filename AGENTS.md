# AGENTS.md

## Scope

- This file is the only source of rules for the Codex GitHub code review bot in this repository. It is self-contained; do not look for rules in external documents.
- It applies to code review comments on pull requests. It does not describe how to implement or run the project.

## Code Review Rules

### Language (highest priority)

- Write every review comment, summary, and question in Korean (한국어). Do not write review text in English, even when the PR title, description, commit messages, or code comments are in English.
	- Keep code identifiers, file paths, commands, and quoted source text in their original form.
	- Keep the priority badge (`P0` to `P3`) as is, and write the explanation in Korean.
	- Do not translate implementation names such as `StorePattern`, `ToastPresenter`, or `MainView`.
- Keep comments concise: one issue per comment, short sentences, and end sentences in Korean noun form where natural (명사형 종결), matching the existing PR style.
- Preferred shape of a comment:
	- Title: `[P2] 인스펙터 안의 Todo 상세에서 뒤로가기가 옵션 페이지로 돌아가지 않음`
	- Location, trigger, impact, and minimal fix, each on its own line in Korean.

### Priorities

- `P0`, `P1`: data loss, security, crashes, concurrency and resource lifetime problems, behavior regressions.
- `P2`: architecture violations, scope drift, missing meaningful tests.
- `P3`: low-impact violations of the repository conventions below.
- Do not report:
	- Matters of taste and style that do not affect behavior.
	- Formatting-only issues that SwiftLint would catch.
	- Speculation that the code does not support.

### What counts as a finding

- Report only issues that the code supports and that have a concrete failure scenario.
- For each finding, include:
	- The file path and line.
	- The condition that triggers it.
	- The impact on users or behavior.
	- The minimum correction.
- Order findings by severity. Do not repeat the same finding in several places.
- Do not claim that tests or runtime behavior were verified if they were not run.
- Do not raise again threads that are already resolved or feedback that was already applied.

### Checks for this repository (DevLog_iOS)

- Behavior preservation:
	- Behavior changes that were not requested, and cleanups outside the requested scope.
	- New logic written where existing logic could have been reused.
- Architecture:
	- No dependency injection between types of the same layer (initializer, stored property, environment, or runtime resolver).
		- The only exception is a SwiftUI `View` in `Application/Presentation` receiving same-layer presentation objects such as a ViewModel, Coordinator, or Store.
	- `Infra` depends on `Data` and `Core`, not on `Domain`.
	- Do not move domain entities to `Core` only because several modules use them.
	- Firebase-specific error detection belongs in `Infra`; `Data` handles domain-level errors after mapping.
	- Widget UI consumes snapshot data only. `WidgetCore` must not depend on Domain, Data, Infra, Persistence, Presentation, or App.
- StorePattern:
	- Keep `@MainActor`, `State`, `Action`, `SideEffect`, and `send -> reduce -> run`.
	- Reducers compute state and return side effects; I/O belongs in `run` or injected services.
	- Do not add task cancellation or async wrappers around operations that are not actually async.
	- Remove reducer-era helper methods left behind after work moved into `run`.
- SwiftUI:
	- No intermediate views, properties, or wrappers that only forward to another view.
	- Feature-owned presentation state of a Store-backed view lives in the Feature's `State`; do not duplicate it as view-local `@State`.
	- View-local `@State` is only for transient rendering and measurement that does not change the feature flow.
	- Do not add accessibility code that was not requested, and do not remove existing accessibility behavior without a reason.
- Design tokens:
	- UI changes must use the existing `ColorPalette` colors (`Color+Assets`), not hard-coded or system colors.
- Localization:
	- Missing keys or translations for new user-facing strings.
	- Large unrelated changes in `.xcstrings`.
- Swift conventions (`P3`):
	- Explicit type annotations that are not required.
	- New Swift file headers whose author is not `opfic`.
	- Prefer `<` and `<=` over `>` and `>=` when the meaning is the same.
- Repository rules:
	- SwiftUI preview code (`#Preview`, `PreviewProvider`, preview-only fixtures) included in a commit.
	- Secrets, tokens, or private configuration files.
	- Unnecessary changes to generated Xcode projects or `Package.resolved`.
	- A PR title that differs from the title of the linked issue.
	- A PR body with sections not declared in the PR template, or with verification results (build, test, lint).
	- Tool attribution text (such as `Co-Authored-By` or `Generated with`) in commits or the PR body.

### Review summary

- Write the findings first, then, in order:
	- Verdict: one of `Pass`, `Block`, `Needs Follow-up`.
	- The scope that was inspected.
	- Verification that could not be done.
	- Limitations.
- `Pass` means no blocking finding in the inspected scope. It does not mean tests were run or runtime behavior was verified.
- If there are no findings, state in Korean that there are none ("지적 없음") together with the inspected scope.
- If required source files could not be read, state the missing prerequisite and do not give `Pass`.
- Final reminder: all of the above output must be written in Korean.
