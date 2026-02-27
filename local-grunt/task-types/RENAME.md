# Task Type: RENAME

Move or rename a file.

## OPERATION Format

```markdown
## OPERATION
- action: RENAME
- source: <absolute path of current file>
- destination: <absolute path of new location/name>
- create_parent_dirs: true | false
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `source` | Yes | Absolute path of the file to move/rename. Must exist. |
| `destination` | Yes | Absolute path of the new location/name. Must NOT exist. |
| `create_parent_dirs` | Yes | If `true`, create intermediate directories for the destination. If `false` and parent directory doesn't exist, report BLOCKED. |

## Rules

1. Source must exist. Destination must NOT exist. If either condition is false, report BLOCKED.
2. If `create_parent_dirs` is `true`, create any missing parent directories for the destination.
3. After the move, the source path must no longer exist and the destination path must exist.
4. This is a move operation. The source is removed.

## Required Preconditions

- `File <source> exists`
- `File <destination> does not exist`
- `Directory <destination parent> exists` (unless `create_parent_dirs: true`)

## Example 1: Rename a File

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-060
- task_type: RENAME
- created_by: Claude
- created_at: 2026-02-27T17:00:00Z
- depends_on: none
- priority: 100
- batch_id: GB-2026-02-27-008

## TARGET
- file: /Users/dev/project/src/utils.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/utils.ts` exists
- [ ] File `/Users/dev/project/src/helpers.ts` does not exist
- [ ] Directory `/Users/dev/project/src` exists

## OPERATION
- action: RENAME
- source: /Users/dev/project/src/utils.ts
- destination: /Users/dev/project/src/helpers.ts
- create_parent_dirs: false

## VALIDATION
- [ ] File `/Users/dev/project/src/helpers.ts` exists and is non-empty
- [ ] File `/Users/dev/project/src/utils.ts` does NOT exist

## ROLLBACK
- On failure: STOP_AND_REPORT
- Recovery: `mv /Users/dev/project/src/helpers.ts /Users/dev/project/src/utils.ts`
```

## Example 2: Move a File to a New Directory

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-061
- task_type: RENAME
- created_by: Claude
- created_at: 2026-02-27T17:05:00Z
- depends_on: none
- priority: 200
- batch_id: GB-2026-02-27-008

## TARGET
- file: /Users/dev/project/src/db.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/db.ts` exists
- [ ] File `/Users/dev/project/src/database/connection.ts` does not exist

## OPERATION
- action: RENAME
- source: /Users/dev/project/src/db.ts
- destination: /Users/dev/project/src/database/connection.ts
- create_parent_dirs: true

## VALIDATION
- [ ] File `/Users/dev/project/src/database/connection.ts` exists and is non-empty
- [ ] File `/Users/dev/project/src/db.ts` does NOT exist
- [ ] Directory `/Users/dev/project/src/database` exists

## ROLLBACK
- On failure: STOP_AND_REPORT
- Recovery: `mv /Users/dev/project/src/database/connection.ts /Users/dev/project/src/db.ts`
```
