# Session End (End of Session)

<!--
  Filename convention: SESSION_END_<AGENT>.md (e.g., SESSION_END_CLAUDE.md)
  Location: docs/memory/handoffs/YYYY-MM-DD/
  For multiple sessions in one day, append a sequence number: SESSION_END_CLAUDE_2.md
-->

Snapshot Date: YYYY-MM-DD
Primary Commit: `(commit hash or "N/A")`
Actor: (your name / agent name)

## Scope Completed

1. **(Feature/task name)**: Brief description of what was done.
2. **(Feature/task name)**: Brief description of what was done.

## Files Changed

| File | Change Summary |
|------|---------------|
| `path/to/file1` | (what changed and why) |
| `path/to/file2` | (what changed and why) |

## Validation Results

- **Command**: `(exact test/build command run)`
- **Result**: PASS / FAIL / PARTIAL
- **Details**: (number of tests passed, failures, warnings)

## Connectivity / Environment Snapshot

<!-- Remove this section if no external services were used. -->

- **Service A**: Reachable / Unreachable (environment: production / staging / sandbox)
- **Service B**: Reachable / Unreachable

## State of Thinking (Context for Next Session)

<!-- This is the most important section for continuity. Capture non-obvious context. -->

- **(Topic)**: (Non-obvious logic, design decisions, or constraints the next developer needs to know)
- **(Partial work)**: (Anything started but not finished, and why)
- **(Gotchas)**: (Pitfalls discovered but not yet fixed)

## Open Items / Risks

- [ ] (Unfinished task or known risk)
- [ ] (Blocker requiring human decision)

## Next Steps

Exact commands or actions for the next developer to continue:

```bash
# (command to run to pick up where you left off)
```

## Repository State

- Branch: `(branch name)`
- Status: Clean commit / Local commit pending push / Uncommitted WIP
- Uncommitted files: (list if any, or "none")
- ACTIVE_SESSIONS.md updated: (yes/no - mark your session COMPLETED or remove your row)
