# Task Type: VALIDATE

Run a command and check the output against expected values. Strictly read-only -- VALIDATE does not change state.

## OPERATION Format

```markdown
## OPERATION
- action: VALIDATE
- command: <exact command to run>
- shell: /bin/bash
- timeout_seconds: <integer>
- expected_exit_code: <integer>
- expected_stdout_contains: <exact string> | any
- expected_stdout_not_contains: <exact string> | none
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `command` | Yes | The exact command to run. |
| `shell` | No | Default: `/bin/bash`. |
| `timeout_seconds` | No | Default: 30. |
| `expected_exit_code` | Yes | The command must exit with this code. |
| `expected_stdout_contains` | Yes | A string that must appear in stdout. Use `any` to skip this check. |
| `expected_stdout_not_contains` | No | A string that must NOT appear in stdout. Use `none` to skip. Default: `none`. |

## Rules

1. VALIDATE is **read-only**. It checks state but does not change it.
2. The result includes the full stdout/stderr in the `details` field.
3. The `validation_passed` field in the result is `true` if ALL conditions match, `false` otherwise.
4. If `validation_passed` is `false`, this is still a DONE (not FAILED) -- the validation ran successfully, it just reported a negative result. The brains decides what to do.

## Required Preconditions

- `Directory <working_directory> exists` (if specified)

## Example 1: Verify TypeScript Compiles

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-080
- task_type: VALIDATE
- created_by: Claude
- created_at: 2026-02-27T19:00:00Z
- depends_on: GT-2026-02-27-003
- priority: 900
- batch_id: GB-2026-02-27-010

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project` exists
- [ ] File `/Users/dev/project/tsconfig.json` exists
- [ ] Command `npx` is available in PATH

## OPERATION
- action: VALIDATE
- command: npx tsc --noEmit --project /Users/dev/project/tsconfig.json
- shell: /bin/bash
- timeout_seconds: 120
- expected_exit_code: 0
- expected_stdout_contains: any
- expected_stdout_not_contains: error TS

## VALIDATION
- not_applicable (this task IS the validation)

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 2: Check a File Contains Expected Content

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-081
- task_type: VALIDATE
- created_by: Claude
- created_at: 2026-02-27T19:05:00Z
- depends_on: GT-2026-02-27-020
- priority: 900
- batch_id: GB-2026-02-27-010

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] File `/Users/dev/project/config/database.json` exists

## OPERATION
- action: VALIDATE
- command: node -e "const c = JSON.parse(require('fs').readFileSync('/Users/dev/project/config/database.json', 'utf8')); console.log(c.host ? 'VALID' : 'INVALID');"
- shell: /bin/bash
- timeout_seconds: 10
- expected_exit_code: 0
- expected_stdout_contains: VALID
- expected_stdout_not_contains: INVALID

## VALIDATION
- not_applicable (this task IS the validation)

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 3: Run Tests for a Specific Module

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-082
- task_type: VALIDATE
- created_by: Claude
- created_at: 2026-02-27T19:10:00Z
- depends_on: GT-2026-02-27-040
- priority: 900
- batch_id: GB-2026-02-27-010

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project` exists
- [ ] Command `npx` is available in PATH

## OPERATION
- action: VALIDATE
- command: npx jest --testPathPattern="auth" --no-coverage 2>&1
- shell: /bin/bash
- timeout_seconds: 120
- expected_exit_code: 0
- expected_stdout_contains: Tests:
- expected_stdout_not_contains: FAIL

## VALIDATION
- not_applicable (this task IS the validation)

## ROLLBACK
- On failure: STOP_AND_REPORT
```
