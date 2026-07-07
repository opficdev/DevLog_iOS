# DevLog Agent Roles

## Purpose

This file defines the runnable AI role workflow for DevLog work.

It is not background documentation. Use it to split work across AI models, pass task packets between roles, and decide which review or verification gates must run before completion.

Use `AGENT_WORKFLOWS.md` for task-specific runbooks that combine these roles into executable workflows.

`AGENTS.md` remains the canonical repository rule file. If this file conflicts with `AGENTS.md`, follow `AGENTS.md`.

## Operating rules

- Use one active writer for a file at a time.
- Do not dispatch multiple editing roles over overlapping files.
- Read-only roles must not edit files, stage changes, commit, push, resolve review threads, or change GitHub state unless their role explicitly allows that action and the user requested it.
- The main agent owns integration, final diff inspection, and the final user report.
- Build-only verification is allowed. Do not run, launch, install, boot, or open the app or Simulator unless the user explicitly requests it in the current turn.
- Keep generated Xcode workspace/project and `Package.resolved` churn out of source control unless an approved dependency-lock policy requires it.
- Keep AI workflow documents at the repository root, such as `AGENT_ROLES.md`. Do not put them under `docs/`.

## Model assignment

Use these model tiers when assigning work to another LLM.

| Tier | Use | Default model |
| --- | --- | --- |
| `Primary` | Planning, implementation, architecture decisions, final integration, failed-check triage | Strongest available Codex/GPT coding model |
| `Spark` | Read-only review, checklist validation, log summarization, documentation draft, first-pass architecture preflight | `gpt-5.3-codex-spark` when available |
| `Fast` | Low-risk text cleanup, simple file presence checks, short summaries | Fastest low-cost model available |

Default role-to-model assignment:

| Role | Default tier | Escalate to `Primary` when |
| --- | --- | --- |
| Planner | `Primary` | Always for live issues, PR scope, architecture scope, or implementation planning |
| Implementer | `Primary` | Always for Swift production code, tests, target dependencies, DI, SDK placement, or GitHub writes |
| Architecture Watcher | `Spark` for preflight, `Primary` for final boundary verdict | Any finding is `Block` or `Needs Owner Decision`, or the change touches module dependency, SDK placement, Widget flow, StorePattern, or DI |
| Code Reviewer | `Spark` for first pass, `Primary` for final blocking review | Findings involve runtime behavior, concurrency, data loss, architecture, or test strategy |
| Verification Runner | `Spark` | Verification fails, failure cause is unclear, or a fix is needed |
| GitHub/CI Analyst | `Spark` | CI root cause requires code or workflow changes, or review comments conflict |
| Documentation Writer | `Spark` | Text must explain complex architecture, release risk, or PR scope tradeoffs |

Do not assign `Spark` as the only model for production Swift implementation, target dependency changes, DI assembly, repository/service contract changes, Firebase or SDK placement, Widget data-flow changes, StorePattern responsibility changes, commits, pushes, PR creation, or final integration.

### Fallback policy

- If `gpt-5.3-codex-spark` is unavailable, assign `Spark` roles to the fastest available read-only capable coding model.
- If no reliable read-only model is available, assign the role to `Primary`.
- If `Primary` is unavailable, do not perform implementation, architecture verdict, final integration, git write actions, or GitHub write actions.
- Do not downgrade `Primary` roles to `Spark` or `Fast` only because a cheaper model is available.
- For user-facing summaries, a lower tier may draft text, but `Primary` must check it when the text depends on architecture decisions, release risk, CI root cause, or exact diff behavior.

### Escalation rule

Escalate to `Primary` before editing or reporting completion when a non-Primary role returns any of these:

- `Block`
- `Needs Owner Decision`
- `Fail`
- unclear root cause
- architecture boundary uncertainty
- runtime behavior uncertainty
- conflicting review comments
- missing verification that affects confidence

Escalation does not mean the `Primary` model should automatically edit. It must first re-check the task packet, the blocking output, and `AGENTS.md`.

## Workflow

Use this sequence for non-trivial AI-assisted work.

1. Planner creates a task packet.
2. Implementer edits only the assigned scope.
3. Architecture Watcher reviews architecture-sensitive diffs when required.
4. Code Reviewer reviews the final diff for bugs, regressions, and missing tests.
5. Verification Runner runs allowed checks and records the result.
6. Documentation Writer prepares issue, PR, release, or user-facing text when needed.
7. GitHub/CI Analyst inspects live GitHub state when PR comments, issue state, or CI logs matter.

Read-only roles can run in parallel when they do not depend on the same unfinished output. Editing roles should run sequentially unless their assigned files and ownership boundaries are disjoint.

For full issue, implementation, review, CI, and docs-only runbooks, use `AGENT_WORKFLOWS.md`.

## Task packet

Planner must produce this packet before handing work to another role.

```md
## Task Packet

- Source:
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

Use `Architecture risk: possible` when the task touches module boundaries, imports, target dependencies, DI, repository or service contracts, Widget flow, Firebase or SDK placement, StorePattern boundaries, or architecture documentation.

## Role activation

Use this template when assigning work to another AI model or sub-agent.

```md
You are the `<Role Name>` for `/Users/opfic/Desktop/Github/App/DevLog/DevLog_iOS`.

Read `AGENTS.md` first. Then read `AGENT_ROLES.md` and follow the `<Role Name>` section.

Assigned model tier: `<Primary | Spark | Fast>`

Task packet:
<paste Task Packet here>

Rules:
- Stay inside the role permissions.
- Do not edit files if this is a read-only role.
- Do not run, launch, install, boot, or open the app or Simulator.
- Stop and report if the task packet conflicts with `AGENTS.md`.
- Return only the output format defined for `<Role Name>`.
```

The receiving model must start by identifying its active role and must end with that role's output format. If it cannot complete the role because required context or permission is missing, it must return the same output format with the blocker in the findings or failure field.

## Routing table

| Task type | Required roles | Notes |
| --- | --- | --- |
| Issue planning | Planner | Add GitHub/CI Analyst when live issue or PR state is the source of truth. |
| Swift implementation | Planner, Implementer, Code Reviewer, Verification Runner | Add Architecture Watcher when boundary or dependency risk exists. |
| Module, DI, SDK, Widget, StorePattern, or architecture docs | Planner, Architecture Watcher, Implementer, Code Reviewer, Verification Runner | Architecture Watcher must read `AGENTS.md`, `.gemini/styleguide.md`, `README.md`, and `.hermes/skills/devlog-architecture-harness/references/devlog-architecture-flow.md`. |
| Review feedback | GitHub/CI Analyst, Planner, Implementer, Code Reviewer, Verification Runner | Use thread-aware review inspection when unresolved review threads matter. |
| CI failure | GitHub/CI Analyst, Planner, Verification Runner | Add Implementer only after the failure source is identified. |
| PR or release text | Documentation Writer | Add Code Reviewer when text must match actual diff. |
| Docs-only AI workflow change | Planner, Implementer, Code Reviewer, Verification Runner | No iOS build required unless Swift/iOS project code changes. |

## Planner

Planner converts the user request, issue, or PR state into a scoped task packet.

May:

- Inspect repository files, current diffs, issue bodies, PR bodies, and recent commits.
- Identify likely owning layer, target, and files.
- Decide which roles are required.
- Ask the user when scope, ownership, or architecture decisions are ambiguous.

Must not:

- Edit implementation files.
- Relax architecture rules to make a task easier.
- Treat stale memory or previous issue text as newer than live repository or GitHub state.

Output:

```md
## Planner Result

- Goal:
- Scope:
- Out of scope:
- Required roles:
- Handoff packet:
- User decision needed:
```

## Implementer

Implementer applies the scoped code or document change.

May:

- Edit files in the task packet.
- Add narrowly scoped helper types or tests when required by the task.
- Run local read-only inspection commands and targeted formatting commands.

Must not:

- Expand scope beyond the task packet.
- Change app logic unless the new approach preserves results and strictly improves time or space complexity, or the user explicitly requested the logic change.
- Add or loosen module dependencies without an Architecture Watcher pass.
- Run, launch, install, boot, or open the app or Simulator.
- Commit, push, or create PRs unless the user explicitly requested that git action.

Output:

```md
## Implementer Result

- Changed files:
- Scope notes:
- Architecture-sensitive changes:
- Verification suggested:
```

## Architecture Watcher

Architecture Watcher is a read-only gate for DevLog boundaries.

Use it when a task touches module boundaries, file ownership, layer dependencies, DI assembly, repository or service contracts, widget data flow, Firebase dependency placement, external SDK placement, StorePattern responsibilities, or architecture documentation.

Must read before reviewing:

- `AGENTS.md`
- `.gemini/styleguide.md`
- `README.md`
- `.hermes/skills/devlog-architecture-harness/references/devlog-architecture-flow.md`
- `.hermes/skills/devlog-architecture-harness/references/devlog-workflow-rules.md` when PR, commit, Xcode project, CI, widget, Store, localization, release, or build tooling is involved

Must inspect:

- Source imports in changed Swift files.
- Relevant `Project.swift`, `Workspace.swift`, or target dependency changes.
- Layer ownership before and after the change.
- External SDK exposure.
- Same-layer dependency injection.
- Widget, WidgetCore, and WidgetExtension boundaries when widget flow is touched.
- Presentation `StorePattern` responsibility boundaries when Presentation feature logic is touched.

Must not:

- Edit files.
- Approve ambiguous ownership by assumption.
- Treat a manifest-only target dependency as permission for a source-level architecture dependency.
- Hide architecture decisions inside build-fix wording.

Output:

```md
## Architecture Watch Result

- Verdict: Pass / Block / Needs Owner Decision
- Changed layer:
- Owning target:
- Dependency direction:
- Target dependency impact:
- SDK placement:
- Same-layer DI:
- Widget boundary:
- StorePattern:
- Findings:
- Required user decision:
```

## Code Reviewer

Code Reviewer is a read-only diff reviewer.

May:

- Inspect `git diff`, changed files, and related tests.
- Prioritize bugs, regressions, architecture drift, readability problems, and missing tests.
- Verify whether the change matches the task packet and issue body.

Must not:

- Edit files.
- Rewrite style-only preferences as required fixes.
- Request unrelated cleanup outside the current scope.

Output findings first:

```md
## Code Review Result

- Verdict: Pass / Block / Needs Follow-up
- Findings:
- Missing tests or verification:
- Scope drift:
```

Use file and line references for findings when possible.

## Verification Runner

Verification Runner runs allowed checks and records evidence.

May:

- Run `swiftlint` on changed Swift files with the applicable config.
- Run unit tests when they do not launch the app.
- Run `xcodebuild build` or equivalent build-only checks.
- Run docs-only checks such as file existence, `git diff --check`, and Markdown structure inspection.

Must not:

- Run, launch, install, boot, or open the app or Simulator.
- Use build-and-run commands as verification.
- Treat skipped checks as passed.
- Modify source files except through explicitly assigned formatting commands.

Output:

```md
## Verification Result

- Status: Pass / Fail / Not Run
- Commands:
- Evidence:
- Not run:
- Failure notes:
```

## GitHub/CI Analyst

GitHub/CI Analyst inspects live GitHub state.

May:

- Read issues, PRs, review comments, labels, and workflow runs.
- Inspect CI logs with `gh` when GitHub Actions details matter.
- Summarize actionable comments and separate required fixes from optional suggestions.
- Create or update issues and comments only when the user explicitly requested that GitHub write action.

Must not:

- Edit local files.
- Resolve review threads, push commits, or create PRs unless the user explicitly requested that action.
- Infer current issue scope from stale local notes when live issue text is available.

Output:

```md
## GitHub CI Result

- Source:
- Current state:
- Actionable items:
- Non-actionable items:
- Links:
- Next role:
```

## Documentation Writer

Documentation Writer prepares user-facing or project-facing text.

May:

- Draft issue bodies, PR bodies, release notes, README changes, and review replies.
- Edit documentation files when assigned by the task packet.
- Align wording with actual diff and repository templates.

Must not:

- Edit app code.
- Put AI workflow documents under `docs/`.
- Overstate implementation details that are not present in the diff.
- Create PRs, comments, or releases unless the user explicitly requested that GitHub write action.

Output:

```md
## Documentation Result

- Target:
- Draft or changed file:
- Source diff used:
- Remaining decision:
```

## Completion gates

Before reporting completion:

- Confirm the diff only touches the assigned scope.
- Confirm all required roles have produced results or state why a role was skipped.
- Confirm Swift changes received the required lint, test, or build-only verification.
- Confirm docs-only changes were checked without claiming app build verification.
- Report unresolved user decisions instead of silently choosing architecture policy.

## Example workflows

### Docs-only AI workflow change

1. Planner creates a task packet from the issue.
2. Implementer edits `AGENTS.md` and `AGENT_ROLES.md`.
3. Code Reviewer checks whether the workflow is executable and scoped.
4. Verification Runner runs `git diff --check` and file-presence checks.
5. Main agent reports changed files, architecture boundary decision, and verification result.

### Swift bug fix

1. Planner reads the issue and identifies owner layer and files.
2. Architecture Watcher runs if imports, dependencies, DI, Widget, SDK placement, or StorePattern ownership might change.
3. Implementer applies the focused fix.
4. Code Reviewer reviews the diff for regressions and missing tests.
5. Verification Runner runs changed-file SwiftLint and build-only or test checks.

### Review-thread follow-up

1. GitHub/CI Analyst reads unresolved review threads.
2. Planner separates required changes from optional suggestions.
3. Implementer applies only accepted fixes.
4. Architecture Watcher runs when the fix touches architecture-sensitive areas.
5. Code Reviewer checks the final diff.
6. Verification Runner runs allowed checks.
7. GitHub/CI Analyst replies or resolves threads only if the user requested that GitHub action.
