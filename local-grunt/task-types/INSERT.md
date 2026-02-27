# Task Type: INSERT

Insert content at a specific location in an existing file, immediately after an anchor string.

## OPERATION Format

```markdown
## OPERATION
- action: INSERT
- insert_after: |
    ```<language>
    (EXACT anchor string after which to insert)
    ```
- content: |
    ```<language>
    (EXACT content to insert)
    ```
- expected_match_count: <integer>
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `insert_after` | Yes | The exact string to search for. Content is inserted immediately after this string. |
| `content` | Yes | The exact content to insert. |
| `expected_match_count` | Yes | How many times the anchor appears. Must be `1` for unambiguous insertion. If the grunt's count differs, report BLOCKED. |

## Rules

1. The `insert_after` anchor must appear exactly `expected_match_count` times. If the count differs, report BLOCKED.
2. Content is inserted immediately after the anchor string (on a new line if the anchor ends with `\n`).
3. The brains should use a long enough anchor to ensure uniqueness -- typically 2-3 lines.
4. If `expected_match_count` is greater than 1, the content is inserted after EVERY occurrence.

## Required Preconditions

- `File <path> exists`
- `File <path> contains the exact string: <first 40 chars of insert_after>...`

## Example 1: Add an Import Statement After Existing Imports

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-040
- task_type: INSERT
- created_by: Claude
- created_at: 2026-02-27T15:00:00Z
- depends_on: none
- priority: 100
- batch_id: GB-2026-02-27-006

## TARGET
- file: /Users/dev/project/src/auth/login.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/auth/login.ts` exists
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `import { validateCredentials } from './v`

## OPERATION
- action: INSERT
- insert_after: |
    ```typescript
    import { validateCredentials } from './validators';
    ```
- content: |
    ```typescript
    import { createLogger } from '../utils/logger';
    ```
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `import { createLogger } from '../utils/logger';`
- [ ] Command: `grep -n "createLogger" /Users/dev/project/src/auth/login.ts` produces output (exit code 0)

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 2: Insert a Table Row After a Header

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-041
- task_type: INSERT
- created_by: Claude
- created_at: 2026-02-27T15:10:00Z
- depends_on: none
- priority: 500
- batch_id: GB-2026-02-27-006

## TARGET
- file: /Users/dev/project/docs/memory/ACTIVE_SESSIONS.md
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/docs/memory/ACTIVE_SESSIONS.md` exists
- [ ] File `/Users/dev/project/docs/memory/ACTIVE_SESSIONS.md` contains the exact string: `| Developer | Branch | Scope | Files Owned |`

## OPERATION
- action: INSERT
- insert_after: |
    ```markdown
    | Developer | Branch | Scope | Files Owned | Started (UTC) | Status |
    |-----------|--------|-------|-------------|---------------|--------|
    ```
- content: |
    ```markdown
    | Claude | claude/add-auth | Auth module | src/auth/*, tests/auth/* | 2026-02-27T15:00Z | ACTIVE |
    ```
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/docs/memory/ACTIVE_SESSIONS.md` contains the exact string: `| Claude | claude/add-auth |`

## ROLLBACK
- On failure: STOP_AND_REPORT
```
