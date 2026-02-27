# Task Type: RUN

Execute a shell command and report the output.

## OPERATION Format

```markdown
## OPERATION
- action: RUN
- command: <exact shell command>
- shell: /bin/bash
- timeout_seconds: <integer>
- capture: stdout | stderr | both
- expected_exit_code: <integer>
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `command` | Yes | The exact shell command to execute. The grunt runs it verbatim. |
| `shell` | No | Shell to use. Default: `/bin/bash`. |
| `timeout_seconds` | No | Maximum wait time. Default: 30. If exceeded, report FAILED. |
| `capture` | No | What to capture: `stdout`, `stderr`, or `both`. Default: `both`. |
| `expected_exit_code` | Yes | Expected exit code. If actual differs, report FAILED. |

## Rules

1. The command must be self-contained. No pipes to other tasks. No interactive commands (no `vim`, `nano`, `less`, etc.).
2. The grunt captures output and includes it verbatim in the result's `details` field.
3. If the command times out, report FAILED with `step: "command_execution"`, `actual: "TIMEOUT after N seconds"`.
4. The grunt MUST NOT modify the command. Execute exactly as written.
5. RUN tasks typically don't modify files, but they can (e.g., `mkdir -p`). The brains should set expectations accordingly.

## Required Preconditions

- `Directory <working_directory> exists` (if specified)
- Any command availability checks: `Command <cmd> is available in PATH`

## Example 1: Create a Directory

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-070
- task_type: RUN
- created_by: Claude
- created_at: 2026-02-27T18:00:00Z
- depends_on: none
- priority: 50
- batch_id: GB-2026-02-27-009

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project` exists

## OPERATION
- action: RUN
- command: mkdir -p /Users/dev/project/src/database
- shell: /bin/bash
- timeout_seconds: 10
- capture: both
- expected_exit_code: 0

## VALIDATION
- [ ] Directory `/Users/dev/project/src/database` exists

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 2: Install a Specific Dependency

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-071
- task_type: RUN
- created_by: Claude
- created_at: 2026-02-27T18:05:00Z
- depends_on: none
- priority: 100
- batch_id: GB-2026-02-27-009

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project` exists
- [ ] File `/Users/dev/project/package.json` exists
- [ ] Command `npm` is available in PATH

## OPERATION
- action: RUN
- command: npm install --save-exact winston@3.11.0
- shell: /bin/bash
- timeout_seconds: 60
- capture: both
- expected_exit_code: 0

## VALIDATION
- [ ] Command: `grep -c "winston" /Users/dev/project/package.json` outputs a number > 0 (exit code 0)

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 3: List Directory Contents

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-072
- task_type: RUN
- created_by: Claude
- created_at: 2026-02-27T18:10:00Z
- depends_on: none
- priority: 500
- batch_id: GB-2026-02-27-009

## TARGET
- file: N/A
- working_directory: /Users/dev/project/src

## PRECONDITIONS
- [ ] Directory `/Users/dev/project/src` exists

## OPERATION
- action: RUN
- command: ls -la /Users/dev/project/src/
- shell: /bin/bash
- timeout_seconds: 10
- capture: stdout
- expected_exit_code: 0

## VALIDATION
- not_applicable (informational output only)

## ROLLBACK
- On failure: STOP_AND_REPORT
```
