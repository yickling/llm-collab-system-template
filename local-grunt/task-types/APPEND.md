# Task Type: APPEND

Add content to the end of an existing file.

## OPERATION Format

```markdown
## OPERATION
- action: APPEND
- content: |
    ```<language>
    (EXACT content to append)
    ```
- newline_before: true | false
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `content` | Yes | The exact content to append to the end of the file. |
| `newline_before` | Yes | If `true`, add a newline before the appended content if the file doesn't end with one. If `false`, append directly after the last character. |

## Rules

1. The file must exist (precondition).
2. Content is appended verbatim after the current file content.
3. If `newline_before` is `true` and the file's last character is not `\n`, insert one `\n` before the appended content.
4. Validation should confirm the file ends with the expected content.

## Required Preconditions

- `File <path> exists`

## Example 1: Append an Audit Trail Entry

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-030
- task_type: APPEND
- created_by: Claude
- created_at: 2026-02-27T14:00:00Z
- depends_on: none
- priority: 500
- batch_id: GB-2026-02-27-005

## TARGET
- file: /Users/dev/project/docs/memory/AUDIT_TRAIL.md
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/docs/memory/AUDIT_TRAIL.md` exists

## OPERATION
- action: APPEND
- content: |
    ```markdown
    | 2026-02-27 | Claude | feat: add user authentication endpoint | `a1b2c3d` |
    ```
- newline_before: true

## VALIDATION
- [ ] File `/Users/dev/project/docs/memory/AUDIT_TRAIL.md` contains the exact string: `| 2026-02-27 | Claude | feat: add user authentication endpoint | `

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 2: Append an Export to an Index File

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-031
- task_type: APPEND
- created_by: Claude
- created_at: 2026-02-27T14:05:00Z
- depends_on: GT-2026-02-27-021
- priority: 300
- batch_id: GB-2026-02-27-005

## TARGET
- file: /Users/dev/project/src/utils/index.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/utils/index.ts` exists

## OPERATION
- action: APPEND
- content: |
    ```typescript
    export { createLogger } from './logger';
    export type { Logger, LogLevel } from './logger';
    ```
- newline_before: true

## VALIDATION
- [ ] File `/Users/dev/project/src/utils/index.ts` contains the exact string: `export { createLogger } from './logger';`

## ROLLBACK
- On failure: STOP_AND_REPORT
```
