# Session Claim (Start of Session)

<!--
  Filename convention: SESSION_CLAIM_<AGENT>.md (e.g., SESSION_CLAIM_CLAUDE.md)
  Location: docs/memory/handoffs/YYYY-MM-DD/
  For multiple sessions in one day, append a sequence number: SESSION_CLAIM_CLAUDE_2.md
-->

Snapshot Date: YYYY-MM-DD
Actor: (your name / agent name)

## Claimed Scope

(One-sentence summary of what you plan to accomplish this session.)

### Planned Edits (File Ownership)

<!-- These files should match your "Files Owned" column in ACTIVE_SESSIONS.md -->

1. `path/to/file1` - (what you plan to change)
2. `path/to/file2` - (what you plan to change)
3. ...

### Shared File Coordination

<!-- If you need to modify shared files (e.g., schema.sql, package.json), explain what you'll change and why so other developers can avoid conflicts. Remove this section if not applicable. -->

- `shared/file` - (what you'll change and why)

### Integration / Verification Plan

- (How you will verify your changes work: tests, smoke runs, manual checks)
- (Any dependencies on external services or APIs)

## Workspace State

- Branch: `(branch name, following <agent>/<scope> convention)`
- Git status: (clean / dirty - describe uncommitted changes if any)
- Active sessions checked: (yes/no - any conflicts noted?)
- Registered in ACTIVE_SESSIONS.md: (yes/no)
- Reviewed latest memory: (yes/no - which files you read)
- Reviewed latest handoff: (yes/no - key takeaways)

## Notes

(Any additional context, constraints, or decisions made before starting.)
