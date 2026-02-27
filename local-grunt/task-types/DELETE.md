# Task Type: DELETE

Remove a file from the filesystem.

## OPERATION Format

```markdown
## OPERATION
- action: DELETE
- confirm_content_hash: <SHA-256 hash> | skip
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `confirm_content_hash` | Yes | SHA-256 hash of the file content. The grunt computes the hash and compares before deleting. If mismatch, report BLOCKED. Use `skip` to bypass (brains must explicitly opt out). |

## Rules

1. Before deleting, if `confirm_content_hash` is not `skip`, the grunt computes SHA-256 of the file and compares. If mismatch, report BLOCKED -- the file has changed since the brains generated the task.
2. The file must exist (precondition).
3. After deletion, the grunt verifies the file no longer exists.
4. Deletion is irreversible if the file is not in version control. The ROLLBACK section should note this.

## Required Preconditions

- `File <path> exists`

## Example 1: Delete a Deprecated Config File

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-050
- task_type: DELETE
- created_by: Claude
- created_at: 2026-02-27T16:00:00Z
- depends_on: none
- priority: 500
- batch_id: GB-2026-02-27-007

## TARGET
- file: /Users/dev/project/config/legacy.json
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/config/legacy.json` exists

## OPERATION
- action: DELETE
- confirm_content_hash: a3f2b8c9d1e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0

## VALIDATION
- [ ] File `/Users/dev/project/config/legacy.json` does NOT exist

## ROLLBACK
- On failure: STOP_AND_REPORT
- Note: File is tracked in git. Can be recovered with `git checkout HEAD -- config/legacy.json`.
```

## Example 2: Delete a Generated File (Skip Hash)

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-051
- task_type: DELETE
- created_by: Claude
- created_at: 2026-02-27T16:05:00Z
- depends_on: GT-2026-02-27-050
- priority: 500
- batch_id: GB-2026-02-27-007

## TARGET
- file: /Users/dev/project/dist/bundle.js.map
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/dist/bundle.js.map` exists

## OPERATION
- action: DELETE
- confirm_content_hash: skip

## VALIDATION
- [ ] File `/Users/dev/project/dist/bundle.js.map` does NOT exist

## ROLLBACK
- On failure: STOP_AND_REPORT
- Note: Generated file. Can be recreated with `npm run build`.
```
