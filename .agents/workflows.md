# DevLog Agent Workflows

## Purpose

This file defines executable AI workflows for DevLog work.

Use this after reading `AGENTS.md` and `.agents/roles.md`. `.agents/roles.md` defines what each role may do. This file defines how to combine those roles for common project tasks.

If this file conflicts with `AGENTS.md`, follow `AGENTS.md`.

## Main-agent protocol

The main agent must run every workflow with this protocol.

1. Read `AGENTS.md`, then `.agents/roles.md`, then this file.
2. Select one workflow from this file.
3. Create the task packet.
4. Assign only the roles required by the selected workflow.
5. Assign each role a model tier from `.agents/roles.md`.
6. Keep `Primary` roles with the active main agent, and dispatch every `Lightweight` or `Fast` role through the custom agent mapped in `.agents/roles.md`.
7. Dispatch read-only `Lightweight` or `Fast` roles in parallel only when they do not depend on unfinished edits.
8. Do not complete a required `Lightweight` or `Fast` role directly in `Primary`, including when the dispatch tool would inherit the active `Primary` model.
9. Keep `Primary` editing roles sequential unless the files and ownership boundaries are disjoint.
10. Integrate role outputs.
11. Escalate any `Lightweight` or `Fast` blocker to a `Primary` model before editing.
12. Run completion gates.
13. Report changed files, architecture decision, verification result, delegated roles, model tiers used, and unresolved decisions.

Do not skip the task packet. The task packet is the contract between models.

## Universal stop conditions

Stop and ask the user before editing when:

- The task packet conflicts with `AGENTS.md`.
- The requested fix requires relaxing a layer boundary.
- A role needs to run, launch, install, boot, or open the app or Simulator.
- A required `Lightweight` or `Fast` custom agent cannot be loaded or selected, its pinned model is unavailable, or current tool policy requires user permission that has not been granted.
- The current issue or PR scope is unclear after live GitHub inspection.
- Two editing roles would touch the same file.
- A read-only role reports `Block` or `Needs Owner Decision`.
- Verification fails for a reason that suggests a scope or architecture decision.

## Workflow selection

| User request | Workflow |
| --- | --- |
| "이슈 구현", issue number, feature, bug fix | Issue-driven implementation |
| Module, DI, SDK, Widget, StorePattern, architecture docs | Architecture-sensitive implementation |
| PR review comment, unresolved thread, requested changes | Review-thread follow-up |
| Failing GitHub Actions, CI log, workflow failure | CI failure triage |
| PR body, release note, README, issue wording | Documentation-only writing |
| AI role, AGENTS, workflow, or architecture-rule docs | AI workflow maintenance |

## Issue-driven implementation

Use when implementing a live issue or user-scoped code change.

### Role order

1. GitHub/CI Analyst, if live issue or PR state matters.
2. Planner.
3. Architecture Watcher, if `Architecture risk` is `possible` or `confirmed`.
4. Implementer.
5. Code Reviewer.
6. Verification Runner.
7. Documentation Writer, if PR, release, or issue text is needed.

### Task packet source

```md
## Task Packet

- Source: <issue URL, PR URL, or user request>
- Goal:
- Scope:
- Out of scope:
- Expected changed files:
- Current owner:
- Architecture risk: none / possible / confirmed
- Required roles:
- Model assignment:
- Verification:
- Stop conditions:
```

### Execution

- Planner must identify the owning layer and target before Implementer edits Swift code.
- Implementer must edit only files listed in the task packet unless Planner updates the packet.
- Code Reviewer must check scope drift before style concerns.
- Verification Runner must run changed-file SwiftLint for Swift changes and build-only checks when applicable.

### Completion

Report:

```md
## Workflow Result

- Workflow: Issue-driven implementation
- Changed files:
- Architecture decision:
- Verification:
- Remaining decisions:
```

## Architecture-sensitive implementation

Use when the task touches module boundaries, file ownership, layer dependencies, DI assembly, repository or service contracts, Widget flow, Firebase or SDK placement, StorePattern boundaries, or architecture documentation.

### Role order

1. Planner.
2. Architecture Watcher before editing.
3. Implementer, only after Architecture Watcher returns `Pass`.
4. Architecture Watcher after editing, if imports, target dependencies, or ownership changed.
5. Code Reviewer.
6. Verification Runner.

### Architecture Watcher gate

Architecture Watcher must return:

- `Pass` before Implementer edits.
- `Block` when the requested change violates current rules.
- `Needs Owner Decision` when the repository rules require user confirmation.

Implementer must not proceed on `Block` or `Needs Owner Decision`.

### Required inspection

- Changed Swift imports.
- `Workspace.swift` and relevant `Project.swift` files.
- Current owner and proposed owner.
- External SDK placement.
- Same-layer DI.
- Widget and WidgetCore boundaries when touched.
- StorePattern reducer, side effect, and run responsibility when Presentation feature logic is touched.

### Completion

Report:

```md
## Workflow Result

- Workflow: Architecture-sensitive implementation
- Architecture Watcher verdict:
- Changed files:
- Boundary decision:
- Verification:
- Remaining decisions:
```

## Review-thread follow-up

Use when the user asks to address PR review comments or unresolved review threads.

### Role order

1. GitHub/CI Analyst.
2. Planner.
3. Architecture Watcher, if a requested fix touches architecture-sensitive areas.
4. Implementer.
5. Code Reviewer.
6. Verification Runner.
7. GitHub/CI Analyst, only if the user requested replies or thread resolution.

### Execution

- GitHub/CI Analyst must use thread-aware inspection when unresolved review threads matter.
- Planner must classify each comment as required, optional, already handled, or rejected.
- Implementer must apply only accepted fixes.
- Code Reviewer must verify that the final diff addresses the accepted comments without unrelated cleanup.
- GitHub/CI Analyst must mirror the existing PR reply style when replying.

### Completion

Report:

```md
## Workflow Result

- Workflow: Review-thread follow-up
- Addressed comments:
- Deferred or rejected comments:
- Changed files:
- Verification:
- GitHub actions:
```

## CI failure triage

Use when GitHub Actions, merge-risk-watch, release, TestFlight, App Store, or PR CI fails.

### Role order

1. GitHub/CI Analyst.
2. Planner.
3. Verification Runner, if a local reproduction is possible without launching the app.
4. Implementer, only after a concrete root cause is identified.
5. Code Reviewer.
6. Verification Runner.

### Execution

- GitHub/CI Analyst must inspect the failing run, job, and log excerpts before proposing fixes.
- Planner must separate workflow failure, environment failure, dependency failure, and app build failure.
- Implementer must not edit workflow files until the failing step is identified.
- Verification Runner must not treat CI polling as a substitute for local verification when local checks are available.

### Completion

Report:

```md
## Workflow Result

- Workflow: CI failure triage
- Failing run:
- Root cause:
- Changed files:
- Verification:
- Remaining CI risk:
```

## Documentation-only writing

Use for PR body, issue text, release note, README wording, review reply draft, or user-facing explanation.

### Role order

1. Documentation Writer.
2. Code Reviewer, if wording must match a diff.
3. GitHub/CI Analyst, if live issue, PR, or release state matters.
4. Verification Runner, for file presence and Markdown checks when files changed.

### Execution

- Documentation Writer must inspect the actual diff before writing PR or release text.
- When the Documentation Writer role is required, the main agent must dispatch the draft through `documentation_writer` before writing the final response.
- If dispatch requires explicit user permission and it has not been granted, ask before drafting, returning, or posting the Documentation Writer output.
- `Primary` must review the Documentation Writer output against the template, issue scope, and diff before returning or posting it.
- Do not write AI workflow documents under `docs/`.
- If the user asks only for text, return text directly and do not create files.
- If documentation files are changed, keep the change scoped to the requested document.

### Completion

Report:

```md
## Workflow Result

- Workflow: Documentation-only writing
- Target:
- Changed files:
- Source checked:
- Verification:
```

## AI workflow maintenance

Use for `AGENTS.md`, `.agents/roles.md`, this file, `.agents/rules`, or AI role routing changes.

### Role order

1. Planner.
2. Implementer.
3. Code Reviewer.
4. Verification Runner.

Architecture Watcher is required only if the change modifies architecture policy, layer maps, ambiguity gates, or architecture rules.

### Execution

- Keep `AGENTS.md` as the repository-root AI workflow entrypoint.
- Do not add AI workflow documents under `docs/`.
- `AGENTS.md` should stay the short canonical entrypoint.
- `.agents/roles.md` should define role permissions, output formats, and handoff packet shape.
- `.agents/workflows.md` should define executable role sequences.
- `.agents/rules/architecture.md` should define detailed architecture boundaries and ambiguity gates.
- `.agents/rules/project-workflows.md` should define project-specific verification and delivery rules.

### Verification

Verification Runner must run:

```sh
git diff --check -- AGENTS.md .agents .codex/agents
```

If only Markdown workflow files changed, no iOS build is required.

### Completion

Report:

```md
## Workflow Result

- Workflow: AI workflow maintenance
- Changed files:
- Operational change:
- Verification:
- Remaining decisions:
```

## Parallel dispatch guide

Parallelize only these combinations:

- GitHub/CI Analyst reading live GitHub state while Planner inspects local files.
- Architecture Watcher reviewing boundaries while Code Reviewer reviews non-architecture risks after the diff is complete.
- Documentation Writer drafting PR text while Verification Runner runs checks, after the diff is stable.

Do not parallelize:

- Two Implementers over overlapping files.
- Implementer and Code Reviewer before Implementer finishes the diff.
- Verification Runner before the relevant files are saved.
- GitHub write actions with local code edits.

## Role prompt snippets

Use the activation template from `.agents/roles.md`, then set `<Role Name>` to one of:

- `Planner`
- `Implementer`
- `Architecture Watcher`
- `Code Reviewer`
- `Verification Runner`
- `GitHub/CI Analyst`
- `Documentation Writer`

Include the selected workflow name in the task packet `Source` or `Goal` field so the receiving model can align its output to this runbook.

## Task packet examples

### Issue-driven implementation example

```md
## Task Packet

- Source: https://github.com/opficdev/DevLog_iOS/issues/704
- Goal: Define AI agent roles and executable role-based workflows for this repository.
- Scope: Update root AI workflow files and README visual summary only.
- Out of scope: Swift/iOS app code, target dependency changes, architecture rule relocation, GitHub Actions changes, app launch.
- Expected changed files: `AGENTS.md`, `.agents/roles.md`, `.agents/workflows.md`, `README.md`
- Current owner: repository workflow documentation
- Architecture risk: none
- Required roles: Planner, Implementer, Code Reviewer, Verification Runner
- Model assignment: Planner=Primary, Implementer=Primary, Code Reviewer=code_reviewer (Lightweight), Verification Runner=verification_runner (Lightweight)
- Verification: `git diff --check -- AGENTS.md .agents .codex/agents README.md`
- Stop conditions: README `docs/` asset policy changes, Swift/iOS code changes, request to remove architecture rules immediately
```

### Review-thread follow-up example

```md
## Task Packet

- Source: <PR URL or review thread URL>
- Goal: Address accepted review feedback without expanding PR scope.
- Scope: Apply only required review fixes confirmed by GitHub/CI Analyst and Planner.
- Out of scope: Optional suggestions, unrelated cleanup, new architecture policy, app launch.
- Expected changed files: <filled by Planner after reading threads>
- Current owner: <layer and target identified by Planner>
- Architecture risk: none / possible / confirmed
- Required roles: GitHub/CI Analyst, Planner, Implementer, Code Reviewer, Verification Runner
- Model assignment: GitHub/CI Analyst=github_ci_analyst (Lightweight), Planner=Primary, Implementer=Primary, Code Reviewer=code_reviewer (Lightweight) -> Primary if blocking, Verification Runner=verification_runner (Lightweight)
- Verification: changed-file SwiftLint for Swift changes, targeted tests or build-only check when applicable
- Stop conditions: unresolved thread requires owner decision, fix relaxes architecture boundary, two comments conflict, CI failure source is unrelated to review feedback
```
