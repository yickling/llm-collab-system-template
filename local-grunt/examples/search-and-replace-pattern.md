# Example: Search and Replace a Deprecated Function

## Scenario

The brains needs to replace all occurrences of the deprecated `getConfig()` function call with `ConfigService.get()` across the codebase. The brains doesn't yet know which files contain the call.

The brains decomposes this into phases:

1. SEARCH_REPORT to find all occurrences
2. EDIT tasks (one per file) based on the search results
3. VALIDATE that no occurrences remain and the project compiles

In practice, the brains generates Task 1 first, dispatches it, reads the results, then generates Tasks 2-5 based on what was found.

---

## Task 1: Find All Occurrences

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-401
- task_type: SEARCH_REPORT
- created_by: Claude
- created_at: 2026-02-27T14:00:00Z
- depends_on: none
- priority: 50
- batch_id: GB-2026-02-27-050

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

**Grunt returns:**
```
## RESULT
- task_id: GT-2026-02-27-401
- status: DONE
- details: |
    /Users/dev/project/src/app.ts:5:const config = getConfig();
    /Users/dev/project/src/services/email.ts:3:const smtp = getConfig().smtp;
    /Users/dev/project/src/services/email.ts:18:  const from = getConfig().emailFrom;
    /Users/dev/project/src/db/connection.ts:7:const dbUrl = getConfig().databaseUrl;
- files_modified: none
- validation_passed: not_applicable
```

**The brains reads this result and generates the following tasks:**

---

## Task 2: Replace in app.ts

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-402
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T14:05:00Z
- depends_on: GT-2026-02-27-401
- priority: 200
- batch_id: GB-2026-02-27-050

## TARGET
- file: /Users/dev/project/src/app.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/app.ts` exists
- [ ] File `/Users/dev/project/src/app.ts` contains the exact string: `const config = getConfig();`

## OPERATION
- action: EDIT
- find_exact: |
    ```typescript
    const config = getConfig();
    ```
- replace_with: |
    ```typescript
    const config = ConfigService.get();
    ```
- occurrence: ALL
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/app.ts` contains the exact string: `ConfigService.get()`
- [ ] File `/Users/dev/project/src/app.ts` does NOT contain the string: `getConfig()`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 3: Replace in services/email.ts

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-403
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T14:05:00Z
- depends_on: GT-2026-02-27-401
- priority: 200
- batch_id: GB-2026-02-27-050

## TARGET
- file: /Users/dev/project/src/services/email.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/services/email.ts` exists
- [ ] File `/Users/dev/project/src/services/email.ts` contains the exact string: `getConfig()`

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
- expected_match_count: 2

## VALIDATION
- [ ] File `/Users/dev/project/src/services/email.ts` does NOT contain the string: `getConfig()`
- [ ] Command: `grep -c "ConfigService.get()" /Users/dev/project/src/services/email.ts` outputs `2`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 4: Replace in db/connection.ts

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-404
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T14:05:00Z
- depends_on: GT-2026-02-27-401
- priority: 200
- batch_id: GB-2026-02-27-050

## TARGET
- file: /Users/dev/project/src/db/connection.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/db/connection.ts` exists
- [ ] File `/Users/dev/project/src/db/connection.ts` contains the exact string: `getConfig()`

## OPERATION
- action: EDIT
- find_exact: |
    ```typescript
    const dbUrl = getConfig().databaseUrl;
    ```
- replace_with: |
    ```typescript
    const dbUrl = ConfigService.get().databaseUrl;
    ```
- occurrence: ALL
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/db/connection.ts` contains the exact string: `ConfigService.get().databaseUrl`
- [ ] File `/Users/dev/project/src/db/connection.ts` does NOT contain the string: `getConfig()`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 5: Validate No Occurrences Remain and Project Compiles

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-405
- task_type: VALIDATE
- created_by: Claude
- created_at: 2026-02-27T14:05:00Z
- depends_on: GT-2026-02-27-402, GT-2026-02-27-403, GT-2026-02-27-404
- priority: 900
- batch_id: GB-2026-02-27-050

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project/src` exists
- [ ] Command `npx` is available in PATH

## OPERATION
- action: VALIDATE
- command: bash -c 'grep -r "getConfig()" /Users/dev/project/src/ --include="*.ts" && echo "FOUND_DEPRECATED" && exit 1 || echo "NO_DEPRECATED_CALLS" && npx tsc --noEmit --project /Users/dev/project/tsconfig.json'
- shell: /bin/bash
- timeout_seconds: 120
- expected_exit_code: 0
- expected_stdout_contains: NO_DEPRECATED_CALLS
- expected_stdout_not_contains: FOUND_DEPRECATED

## VALIDATION
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Dependency Graph

```
GT-401 (SEARCH_REPORT: find getConfig())
  ├── GT-402 (EDIT: app.ts)
  ├── GT-403 (EDIT: services/email.ts)
  └── GT-404 (EDIT: db/connection.ts)
        └── GT-405 (VALIDATE: no deprecated calls + compiles)
              (depends on 402, 403, 404)
```

## Notes

- This example demonstrates the **two-phase pattern**: search first, then generate edits based on results. The brains dispatches Task 401 alone, waits for the result, then generates Tasks 402-405 with exact strings from the search output.
- Tasks 402, 403, 404 can run in parallel -- they edit different files.
- Task 403 uses `occurrence: ALL` with `expected_match_count: 2` because the search found two occurrences in `email.ts`. The brains derived this count from the search results.
- Task 404 includes more surrounding context in `find_exact` (the full `const dbUrl = ...` line) to avoid matching `getConfig()` in import statements or comments.
- The final VALIDATE combines two checks: (1) no deprecated calls remain, and (2) TypeScript compiles. This is acceptable because both are read-only checks in a single command.
