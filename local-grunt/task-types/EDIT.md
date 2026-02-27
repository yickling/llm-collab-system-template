# Task Type: EDIT

Replace an exact string with another exact string in an existing file.

## OPERATION Format

```markdown
## OPERATION
- action: EDIT
- find_exact: |
    ```<language>
    (EXACT string to find, character-for-character, including whitespace and newlines)
    ```
- replace_with: |
    ```<language>
    (EXACT replacement string)
    ```
- occurrence: FIRST | ALL | <integer N>
- expected_match_count: <integer>
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `find_exact` | Yes | The literal string to search for. Must match character-for-character including whitespace, indentation, and newlines. |
| `replace_with` | Yes | The literal replacement. The grunt substitutes this exactly. |
| `occurrence` | Yes | `FIRST` = replace first match only. `ALL` = replace every match. Integer N = replace the Nth match (1-indexed). |
| `expected_match_count` | Yes | How many times `find_exact` appears in the file. If the grunt's count differs, report BLOCKED. |

## Rules

1. The grunt counts occurrences of `find_exact` in the file. If the count does not equal `expected_match_count`, report BLOCKED immediately.
2. Replacement is literal. No regex, no wildcards, no glob patterns.
3. After replacement, the grunt verifies the file by checking the VALIDATION section.
4. The brains must include at least 3 lines of surrounding context in `find_exact` to ensure unique matching.

## Required Preconditions

The brains must include:
- `File <path> exists`
- `File <path> contains the exact string: <first 40 chars of find_exact>...`

## Example 1: Rename a Function

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-001
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T10:00:00Z
- depends_on: none
- priority: 100
- batch_id: GB-2026-02-27-001

## TARGET
- file: /Users/dev/project/src/api/users.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/api/users.ts` exists
- [ ] File `/Users/dev/project/src/api/users.ts` contains the exact string: `export async function getUser(id: strin`

## OPERATION
- action: EDIT
- find_exact: |
    ```typescript
    // Fetch a single user by ID
    export async function getUser(id: string): Promise<User> {
      const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
      return result.rows[0];
    }
    ```
- replace_with: |
    ```typescript
    // Fetch a single user by ID
    export async function fetchUser(id: string): Promise<User> {
      const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
      return result.rows[0];
    }
    ```
- occurrence: ALL
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/api/users.ts` contains the exact string: `export async function fetchUser(id: string)`
- [ ] File `/Users/dev/project/src/api/users.ts` does NOT contain the string: `function getUser(`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 2: Update a Version Number

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-005
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T10:15:00Z
- depends_on: none
- priority: 500
- batch_id: GB-2026-02-27-002

## TARGET
- file: /Users/dev/project/package.json
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/package.json` exists
- [ ] File `/Users/dev/project/package.json` contains the exact string: `"version": "1.2.3"`

## OPERATION
- action: EDIT
- find_exact: |
    ```json
      "version": "1.2.3",
    ```
- replace_with: |
    ```json
      "version": "1.3.0",
    ```
- occurrence: FIRST
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/package.json` contains the exact string: `"version": "1.3.0"`
- [ ] File `/Users/dev/project/package.json` does NOT contain the string: `"version": "1.2.3"`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 3: Replace All Occurrences of a Deprecated Call

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-010
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T11:00:00Z
- depends_on: GT-2026-02-27-009
- priority: 200
- batch_id: GB-2026-02-27-003

## TARGET
- file: /Users/dev/project/src/services/config.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/services/config.ts` exists
- [ ] File `/Users/dev/project/src/services/config.ts` contains the exact string: `getConfig()`

## OPERATION
- action: EDIT
- find_exact: |
    ```typescript
    getConfig()
    ```
- replace_with: |
    ```typescript
    ConfigService.get()
    ```
- occurrence: ALL
- expected_match_count: 3

## VALIDATION
- [ ] File `/Users/dev/project/src/services/config.ts` does NOT contain the string: `getConfig()`
- [ ] Command: `grep -c "ConfigService.get()" /Users/dev/project/src/services/config.ts` outputs `3`

## ROLLBACK
- On failure: STOP_AND_REPORT
```
