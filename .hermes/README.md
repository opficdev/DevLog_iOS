# Hermes Setup for DevLog

This directory stores the DevLog-specific Hermes skill source.

## Skill

- `skills/devlog-architecture-harness`

Use this skill before module boundary, DI, repository, Firebase-boundary, widget-data-flow, or architecture documentation work in this repository.

## Install into Hermes

Hermes loads installed skills from the user's Hermes skills directory. Keep this repository copy as the project-owned source of truth, then install or copy it into your Hermes profile when needed.

```sh
mkdir -p ~/.hermes/skills/project
cp -R .hermes/skills/devlog-architecture-harness ~/.hermes/skills/project/devlog-architecture-harness
```

After installing, start a new Hermes session and invoke:

```text
/devlog-architecture-harness
```

## Canonical project rules

`AGENTS.md` is the canonical repo-wide rule file. The Hermes skill should stay aligned with it.

Detailed DevLog workflow rules live in:

- `skills/devlog-architecture-harness/references/devlog-architecture-flow.md`
- `skills/devlog-architecture-harness/references/devlog-workflow-rules.md`
