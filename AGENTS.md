# DevLog Agent Instructions

## Scope

These instructions apply only to the repository root.

## Logic preservation and optimization

- Reuse the existing program logic as-is whenever possible.
- Change logic only when the new approach produces exactly the same result and strictly improves time or space complexity.
- If there is no clear complexity improvement, keep the original logic.

## Code modification response style

- When asked to modify code, return only the precise changed locations and the modified code for those locations.
- Do not include full files, unrelated code, or explanatory text unless explicitly requested.
- You do not need to paste code in the prompt after updating it in the repository.

## Naming and Swift style

- In Swift, do not write explicit type annotations unless required.
- Use `opfic` in new Swift file headers.
- Prefer `<` and `<=` over `>` and `>=` when writing comparisons, if the condition can be expressed clearly that way.

## DevLog Architecture Harness

Use this harness before any task that changes module boundaries, file ownership, layer dependencies, DI assembly, repository/service contracts, widget data flow, Firebase dependency placement, or architecture documentation.

Treat this repository as a Tuist-generated, workspace-based modular iOS app. There is no root `Package.swift`; module projects are generated from `Workspace.swift` and each module's `Project.swift`.

### Mandatory flow

1. Read this file, `.gemini/styleguide.md`, `README.md`, and `.hermes/skills/devlog-architecture-harness/references/devlog-architecture-flow.md`.
2. Identify the changed layer and owning target before editing.
3. Inspect the current Swift import direction and Xcode target/framework dependency before deciding.
4. Classify the change as mechanical, architectural, or ambiguous.
5. For ambiguous architecture changes, stop and ask the user before editing.
6. Keep the diff limited to the requested architecture scope.
7. After Swift/iOS code changes, follow the Verification section.
8. Report the changed files, architecture decision, and verification result.

### Current layer map

- `Application/DevLogCore`: shared app primitives such as DI, logging, query/value types, display options, activity kinds, and lightweight widget bridge values such as `WidgetTodoSnapshot`. Core is shared, but shared access alone is not enough reason to move domain entities into Core.
- `Application/DevLogDomain`: entities, repository protocols, use case protocols, and use case implementations. Domain may depend on Core. Domain must not depend on Data, Infra, Persistence, Presentation, App, Widget extension UI, Firebase SDKs, or storage implementations.
- `Application/DevLogData`: repository implementations, DTOs, mappers, data-layer protocols for external services/stores, widget snapshot repository implementations, and widget sync/updater contracts. Data may depend on Domain and Core. Data should not own concrete widget sync handlers, event bus implementations, WidgetCore snapshot model/factory usage, or WidgetKit reload behavior, and should not gain direct Firebase, GoogleSignIn, WidgetKit, or concrete storage implementation details unless the user explicitly approves the boundary change.
- `Application/DevLogInfra`: Firebase, social login, network, link metadata, messaging, and platform service implementations. Infra may depend on Data and Core. Infra must not depend on Domain even if a manifest-only target dependency exists. Firebase/Auth/Firestore/Functions/Messaging-specific behavior belongs here unless the user approves another boundary.
- `Application/DevLogPersistence`: local persistence, user defaults, image store, and non-widget app persistence. Persistence may depend on Data and Core. Widget snapshot generation, widget snapshot persistence orchestration, and WidgetKit reload behavior belong to DevLogWidget.
- `Application/DevLogPresentation`: SwiftUI views, view models, coordinators, UI state structures, presentation-only helpers, and narrow presentation-scoped platform side effects such as notification badge updates. Presentation may depend on Domain and Core. It must not depend on Data, Infra, Persistence, or App.
- `Application/DevLogWidget`: app-side bridge between the app runtime and widget system, widget sync event bus implementation, widget sync/session handlers, auth-session sync provider, widget snapshot generation/persistence orchestration, WidgetKit reload bridge, and `WidgetAssembler`. DevLogWidget may depend on Data, Core, and WidgetCore. It must not depend on Domain, Infra, Persistence, Presentation, or App without explicit user approval.
- `Application/DevLogApp`: composition root, app lifecycle, app delegate, app-level routing, assembler wiring, and app target ownership for widget extension embedding. App may import concrete layers to assemble the dependency graph.
- `Widget/DevLogWidgetCore`: widget snapshot models, factories, keys, app-group constants/defaults store, deep links, and widget-only pure helpers. WidgetCore may depend on Core. It must not depend on Domain, Data, Infra, Persistence, Presentation, App, or DevLogWidget without explicit user approval.
- `Widget/DevLogWidgetExtension`: WidgetKit UI, widget providers, entries, timelines, and extension resources. It should consume WidgetCore outputs rather than app/domain services directly.
- `Firebase/functions`: TypeScript Cloud Functions. Deploy updated functions one by one separately.

### StorePattern flow

- Preserve the existing Presentation `StorePattern`.
- `StorePattern` is `@MainActor` and uses `State`, `Action`, `SideEffect`, and the `send -> reduce -> run` flow.
- Reducers should compute state and return side effects.
- I/O belongs in `run` or injected services, not in reducer state computation.
- Ask before changing reducer, side-effect, or ViewModel responsibility boundaries.

### Ambiguity gate

Ask the user before editing when any of these are true:

- A type could plausibly live in both Core and Domain.
- A shared type is being moved only because multiple modules need access to it.
- A new target dependency would make a lower-level module know a higher-level module.
- A build fix would be achieved by loosening an architecture boundary.
- Firebase, GoogleSignIn, AuthenticationServices, UserNotifications, LinkPresentation, Network, WidgetKit, or storage implementation details would move to another layer.
- A repository protocol, service protocol, assembler, or DI ownership boundary would change.
- WidgetCore would start depending on app/domain/data implementation concepts.
- The requested change suggests cleanup outside the current issue or PR scope.

### Safe mechanical changes

These may proceed after inspection when they do not change architecture meaning:

- Removing unused imports.
- Updating import statements after an already-approved file move.
- Fixing access control needed by an already-approved module boundary.
- Updating tests to match an already-approved public contract.
- Editing docs to reflect the current verified architecture.

## Verification

- If Swift files change, run Homebrew SwiftLint (`swiftlint`) on the changed Swift files.
- For production Swift files, use the applicable source `.swiftlint.yml` config.
- For test Swift files, use `.swiftlint-tests.yml` or the module `Tests/.swiftlint.yml` that inherits from it. Do not lint tests with the root production config.
- If iOS project code changes, verify with Xcode Local MCP when it is available.
- If Xcode Local MCP is unavailable, state that explicitly before using a fallback.
- Do not claim architecture work is complete without checking the diff scope.
- Do not spend time on unrelated generated project or lockfile churn. Keep generated workspace/project and `Package.resolved` changes out of source control unless they are part of an explicitly approved dependency-lock policy.
- For Firebase Cloud Functions, deploy updated functions one by one separately.

## Canonical project rules

- DevLog-specific working rules belong in this repository, not in global agent memory.
- Treat `AGENTS.md` and `.hermes/skills/devlog-architecture-harness` as the canonical DevLog AI working rules.
- If global memory conflicts with this repository, follow this repository.
- For PR, commit, Xcode project, CI, widget, Store, localization, or release workflow details, read `.hermes/skills/devlog-architecture-harness/references/devlog-workflow-rules.md`.
