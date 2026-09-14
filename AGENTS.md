# DevLog iOS Agent Bootstrap

## Scope

- These instructions apply to the repository root.
- Active AI working rules live in Notion under `DevLog Agent Policy`.
- This file is a bootstrap document only. Do not add project policy content here.

## Required policy loading

Before planning, editing, reviewing, verifying, delegating, or performing an external write:

1. Fetch the [DevLog Agent Policy](https://app.notion.com/p/3dbb88a8aa5481e296e0f9cdc243d5b0) index through the connected Notion MCP.
2. Verify that the index is under the [DevLog](https://app.notion.com/p/368b88a8aa5480a5a722d48529e6be96) page and use only policies marked `Active` in that index.
3. Load `General` and `iOS` for every task.
4. Load every task-specific policy whose route matches the request. Routes are cumulative.
5. Load `Decision Memory` only when its trigger in the active index applies.

If Notion MCP or a required active policy is unavailable, stop the DevLog task and report the unavailable policy. Do not use removed repository rules or Codex memory as a fallback.

## Source boundaries

- Active Notion policies are the source of AI working rules.
- Current repository code, configuration, templates, CI workflows, and product documentation are the source of implementation facts.
- Decision Memory and Codex memory provide historical context only and must not override active policies or current repository evidence.
- Keep credentials, tokens, and private configuration out of this repository.
