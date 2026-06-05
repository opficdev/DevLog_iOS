---
name: devlog-architecture-harness
description: Use before architecture, modularization, dependency-boundary, DI, repository, Firebase-boundary, or widget-data-flow work in the SwiftUI_DevLog repository.
version: 1.0.0
metadata:
  hermes:
    tags:
      - swift
      - ios
      - architecture
      - modularization
      - devlog
    category: project
---

# DevLog Architecture Harness

## When to use

Use this skill in the repository root when the task touches any of these areas:

- Module boundary changes.
- File moves across `Application/DevLog*` or `Widget/DevLog*` targets.
- Import or target dependency changes.
- DI assembler wiring.
- Repository, service, store, or use case contracts.
- Firebase, social login, network, link metadata, notification, or WidgetKit dependency placement.
- Widget snapshot, App Group, or widget deep-link data flow.
- Architecture diagrams, README architecture text, or PR architecture explanation.

This repository is a Tuist-generated, workspace-based modular iOS app. There is no root `Package.swift`; module projects are generated from `Workspace.swift` and each module's `Project.swift`.

## Required project context

Before editing, read:

1. `AGENTS.md`
2. `.gemini/styleguide.md`
3. `README.md`
4. `references/devlog-architecture-flow.md`
5. `references/devlog-workflow-rules.md` when the task involves PR review, commits, Xcode project files, CI, widgets, Store reducers, localization, or release/build tooling.

Then inspect the concrete files and imports related to the requested change. Do not rely on the layer names alone.

## Procedure

### 1. Classify the request

Classify the task as one of these:

- `mechanical`: unused import cleanup, approved rename fallout, approved access-control adjustment, docs sync.
- `architectural`: module dependency, layer ownership, DI, protocol boundary, external SDK placement, widget data flow.
- `ambiguous`: more than one layer could reasonably own the type or dependency.

If the task is `ambiguous`, stop and ask the user before editing.

### 2. Build a boundary note

For every architecture task, write a short internal boundary note before editing:

- Current owner.
- Proposed owner.
- Current imports.
- Proposed imports.
- Dependency direction.
- Xcode target/framework dependency impact.
- External SDK exposure.
- Whether user confirmation is required.

### 3. Apply the ambiguity gate

Ask the user before editing when:

- Core vs Domain ownership is unclear.
- A shared type is being moved only because multiple modules need access.
- Firebase/Auth/Firestore/Functions/Messaging-specific logic would leave Infra.
- WidgetCore would depend on Domain, Data, Infra, Persistence, Presentation, or App.
- Presentation would depend on Data, Infra, Persistence, or App.
- Data would gain concrete SDK or storage implementation details.
- The Presentation `StorePattern` flow or reducer responsibility would change.
- A compile fix requires relaxing the intended architecture.
- The change is outside the requested issue or PR scope.

### 4. Edit narrowly

When the boundary is clear:

- Keep the diff limited to the requested task.
- Preserve existing logic unless the user explicitly approved logic changes.
- Prefer existing DevLog naming and layer patterns.
- Preserve the existing Presentation `StorePattern`: `@MainActor`, `State`, `Action`, `SideEffect`, and `send -> reduce -> run`.
- Do not introduce unrelated cleanup.
- Do not change lockfiles unless dependency resolution is part of the task.

### 5. Verify

For Swift/iOS code changes:

- Follow the repository `AGENTS.md` Verification section.
- Inspect the final diff for architecture-scope drift.

For docs-only or harness-only changes:

- Verify file presence.
- Check Markdown for obvious broken structure.
- No iOS build is required.

## Required response shape

After completion, report only:

- Changed files.
- Architecture boundary decision.
- Verification result.
- Any user decisions still needed.

## Do not do

- Do not infer project-specific architecture policy from generic Clean Architecture rules when DevLog already has a concrete pattern.
- Do not move domain entities to Core just because multiple modules need them.
- Do not hide architecture decisions inside build-fix wording.
- Do not broaden a modularization task into unrelated Firestore, Messaging, or UI safety edits.
- Do not mark work complete if the diff contains unrelated project-file or lockfile churn.
