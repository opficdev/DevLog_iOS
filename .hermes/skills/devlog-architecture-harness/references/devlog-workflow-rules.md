# DevLog Workflow Rules

This reference holds DevLog-specific working rules that should live with the project, not in global agent memory.

## Canonical source

- Treat this repository's `AGENTS.md` and `.hermes/skills/devlog-architecture-harness` as the canonical DevLog working rules.
- Use global memory only as historical context. If global memory conflicts with this repository, follow the repository.
- Before changing architecture rules, update the repository-local rules first.

## Verification

- Follow `AGENTS.md` for the canonical lint and build verification policy.
- Run Homebrew SwiftLint (`swiftlint`) on changed Swift files.
- Lint production Swift files with the applicable source `.swiftlint.yml` config.
- Lint test Swift files with `.swiftlint-tests.yml` or the module `Tests/.swiftlint.yml` that inherits from it. Do not use the root production config for tests.
- Prefer Xcode Local MCP for iOS project code changes.
- If Xcode Local MCP is unavailable or fails because of session transport, state that explicitly before using a fallback.
- This repository is workspace-based. Prefer workspace/scheme context over standalone project builds when dependencies cross module projects.
- CI truth lives in `.github/workflows/build.yml`: select Xcode 26.3, install Tuist with mise, run `tuist generate --no-open`, then build `DevLog.xcworkspace` scheme `DevLogApp` with `-resolvePackageDependencies`, `-skipPackagePluginValidation`, and `-skipMacroValidation`.
- CI is build validation, not a full test run, unless the workflow changes.
- Avoid unrelated generated project and `Package.resolved` churn. Generated Xcode workspace/project files should not be tracked unless the project explicitly changes that policy.

## Xcode project file work

- Inspect Swift imports and Tuist target dependencies together.
- Validate generated project structure by rerunning `tuist generate --no-open` and building the workspace.
- `plutil -lint` does not prove Xcode save behavior is healthy; for Xcode save crashes, inspect crash reports and project-reference call stacks.
- Do not force a single `objectVersion` across projects. Treat Xcode's actual save output as the source of truth.
- For synchronized-root cleanup, verify on copied files or a narrowed rule set before touching real project files.
- When changing project structure, update the Tuist manifest first and treat generated Xcode project churn as disposable output.
- Do not promote a manifest-only target dependency to an allowed architecture direction. Check source imports and ownership before updating the layer map.

## PR and review handling

- Write DevLog PR and review text in Korean.
- Follow `.github/pull_request_template.md` for PR body structure.
- If the user asks for PR content only, return the Markdown directly and do not create files.
- For unresolved GitHub review threads, use thread-aware inspection such as `gh api graphql` review threads or the `gh-address-comments` skill. Flat comments are not enough.
- Handle narrowed review feedback one item at a time.
- Verify a review suggestion against the real code and diff before accepting it.
- If a cleanup is deferred to an issue, show the issue URL visibly rather than hiding it behind an inline Markdown link when the user asks for review/PR note text.

## Commit guidance

- If the user says they will commit or asks only for a commit message, provide commit-message guidance instead of committing.
- Before proposing a commit message, inspect the actual diff and recent `git log`.
- Match the repository's current Korean style and prefix pattern.
- If the user explicitly specifies a prefix or noun-phrase ending, follow it exactly.
- For broad architecture refactors, split commits by layer when the user asks for staged commits.

## Architecture staging

- For modular refactors, state the next stage before editing when the user asks what comes next.
- When the user wants explicit phases, keep phases clean even if intermediate commits temporarily break the build.
- A common DevLog modularization sequence is external dependency removal, architecture application, then reattaching removed modules by layer.
- Keep project-file, lockfile, and code changes separated when the task scope requires clean review.
- Do not broaden architecture work into unrelated Firestore, Messaging, UI, or safety edits.

## Layer-internal dependency injection

- Do not inject dependencies between types that belong to the same layer.
- This includes initializer injection, stored-property injection, environment injection, and resolving same-layer types through `DIContainer`.
- The only allowed exception is a SwiftUI `View` file in `Application/DevLogPresentation` receiving same-layer presentation objects such as a ViewModel, Coordinator, or Store for UI composition.
- The exception does not apply to non-View files in Presentation, and does not apply to Core, Domain, Data, Infra, Persistence, Widget, App, WidgetCore, WidgetExtension, or Firebase functions.

## Data, Domain, and Infra boundary

- Do not move domain entities to Core only because multiple modules need them.
- Keep protocol location and implementation layer distinct when explaining or changing boundaries.
- If a Data protocol is implemented by Infra, every type in that protocol signature must be visible to Infra.
- `DevLogInfra` should depend on Data and Core, not Domain. Do not treat a manifest-only Domain target dependency as architecture permission.
- Prefer a Data-side boundary value plus repository mapping when Infra should not import Domain.
- For example, keep the app-facing Domain query separate from an Infra-facing Data query when that avoids Domain coupling in service protocols.
- Firebase-specific error detection belongs in Infra; Data should handle domain-level errors after mapping.
- Data and Presentation currently keep narrow social-login cancellation classification in `DataLayerError` and `Error+SocialLogin`. Do not expand that into concrete login implementation or broader SDK ownership without explicit approval.

## Presentation StorePattern

- Preserve the existing `StorePattern` shape: `@MainActor`, `State`, `Action`, `SideEffect`, `send -> reduce -> run`.
- Reducers compute state and return side effects.
- I/O belongs in `run` or injected services.
- Presentation currently owns narrow notification badge side effects through `UserNotifications`. Do not expand that into push service or messaging ownership.
- Do not leave reducer-era helper methods behind after moving work into `run`.
- Before adding task cancellation or async wrappers, inspect whether the underlying operation is actually async.

## Widget flow

- Widget UI should consume snapshot data, not app/domain services.
- `DevLogWidgetCore` should stay free of Domain, Data, Infra, Persistence, Presentation, and App dependencies unless the user explicitly approves a boundary change.
- Prefer an app-driven snapshot flow: app/runtime data fetch, snapshot generation, App Group storage, WidgetCore model/factory, WidgetExtension rendering.
- `WidgetTodoSnapshot` is a lightweight snapshot value, not a full domain `Todo`.
- Do not make `Todo.number` or `WidgetTodoSnapshot.number` non-optional without a separate saved-vs-draft model decision.
- If a widget sync flow needs one timestamp for multiple snapshots, capture `Date()` once and pass it through to avoid midnight or quarter-boundary drift.

## Localization

- For `.xcstrings`, use `jq empty` for structural validation when `plutil -lint` reports format-related false failures.
- Keep `.xcstrings` cleanup surgical and inspect the diff first if the file is already dirty.

## Release and private config

- `release.yml` creates GitHub releases after merged PRs into `main` from `develop`; it does not upload to App Store/TestFlight by itself.
- TestFlight workflow private config comes from the project-specific private config action.
- Runtime/build-required private files must be restored through the documented project workflow, not guessed.
