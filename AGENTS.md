# DevLog Agent Instructions

## Scope

- These instructions apply only to the repository root.
- Read every route that matches the current task. Routes are cumulative.

## Required routing

| Task | Required document |
| --- | --- |
| Every task | `.agents/rules/general.md` |
| Non-trivial design, planning, implementation, review, or verification | `.agents/roles.md` |
| Repeatable role-based execution | `.agents/workflows.md` |
| Approved Spec required by a non-trivial workflow | `.agents/specs/README.md` |
| Module boundaries, file ownership, layer dependencies, DI, repository/service contracts, external SDK placement, Widget flow, `StorePattern`, or architecture documentation | `.agents/rules/architecture.md` |
| PR, review thread, commit, Xcode project, CI, verification, localization, release, or build tooling | `.agents/rules/project-workflows.md` |

## Routing rules

- `AGENTS.md` is the repository entrypoint and routing source.
- `.agents/rules/general.md` applies to every task.
- Read all matching task-specific documents before planning, editing, reviewing, or verifying.
- For architecture work, also read `README.md` before editing.
- For a delegated role, read `.agents/roles.md` and follow the assigned role section and output format.
- Use `.agents/workflows.md` when the task matches one of its executable workflows.
- For a non-trivial design or implementation workflow, create a `Design Brief`, obtain a `Designer Result`, and use an approved Spec before fixing the `Task Packet`.
- If repository-local instructions conflict with global memory, follow the repository-local instructions.
- Write DevLog PR and review text in Korean.
