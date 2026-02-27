# Task Type: SEARCH_REPORT

Search for a pattern in files and report the results. Strictly read-only -- SEARCH_REPORT does not modify anything.

## OPERATION Format

```markdown
## OPERATION
- action: SEARCH_REPORT
- search_command: <exact grep/find command>
- shell: /bin/bash
- scope: <directory path(s) to search>
- report_format: FULL_OUTPUT | COUNT_ONLY | FILE_LIST_ONLY
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `search_command` | Yes | The exact search command to execute (usually `grep` or `find`). |
| `shell` | No | Default: `/bin/bash`. |
| `scope` | Yes | The directory path(s) being searched. Informational -- the actual scope is in the command. |
| `report_format` | Yes | How to report results. `FULL_OUTPUT` = raw command output. `COUNT_ONLY` = number of matches. `FILE_LIST_ONLY` = just file paths. |

## Rules

1. **Strictly read-only.** The grunt must NOT modify anything.
2. The grunt reports the raw output of the search command in its result's `details` field.
3. VALIDATION is `not_applicable` for SEARCH_REPORT.
4. The brains uses these results to generate subsequent EDIT/INSERT tasks. The grunt does NOT do this chaining.
5. If the search returns no results, that is a valid DONE result (not a failure). The `details` field should say "No matches found."

## Required Preconditions

- `Directory <scope> exists`

## Example 1: Find All Occurrences of a Function

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-090
- task_type: SEARCH_REPORT
- created_by: Claude
- created_at: 2026-02-27T20:00:00Z
- depends_on: none
- priority: 50
- batch_id: GB-2026-02-27-011

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project/src` exists

## OPERATION
- action: SEARCH_REPORT
- search_command: grep -rn "getConfig()" /Users/dev/project/src/ --include="*.ts"
- shell: /bin/bash
- scope: /Users/dev/project/src/
- report_format: FULL_OUTPUT

## VALIDATION
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```

**Expected result (example)**:
```
## RESULT
- task_id: GT-2026-02-27-090
- status: DONE
- details: |
    /Users/dev/project/src/services/config.ts:15:  const dbUrl = getConfig().databaseUrl;
    /Users/dev/project/src/services/config.ts:28:  const port = getConfig().port;
    /Users/dev/project/src/services/config.ts:41:  const secret = getConfig().jwtSecret;
    /Users/dev/project/src/app.ts:8:  const config = getConfig();
- files_modified: none
- validation_passed: not_applicable
```

## Example 2: Count Occurrences of a Pattern

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-091
- task_type: SEARCH_REPORT
- created_by: Claude
- created_at: 2026-02-27T20:05:00Z
- depends_on: none
- priority: 50
- batch_id: GB-2026-02-27-011

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project/src` exists

## OPERATION
- action: SEARCH_REPORT
- search_command: grep -rc "TODO" /Users/dev/project/src/ --include="*.ts"
- shell: /bin/bash
- scope: /Users/dev/project/src/
- report_format: COUNT_ONLY

## VALIDATION
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 3: List Files Matching a Pattern

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-092
- task_type: SEARCH_REPORT
- created_by: Claude
- created_at: 2026-02-27T20:10:00Z
- depends_on: none
- priority: 50
- batch_id: GB-2026-02-27-011

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project/src` exists

## OPERATION
- action: SEARCH_REPORT
- search_command: find /Users/dev/project/src -name "*.test.ts" -type f
- shell: /bin/bash
- scope: /Users/dev/project/src/
- report_format: FILE_LIST_ONLY

## VALIDATION
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```
