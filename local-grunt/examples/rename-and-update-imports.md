# Example: Rename File and Update Imports

## Scenario

The brains needs to rename `/Users/dev/project/src/utils.ts` to `/Users/dev/project/src/helpers.ts` and update all import references across the codebase.

The brains already knows (from prior analysis) that the following files import from `./utils` or `../utils`:

- `/Users/dev/project/src/app.ts` -- `import { formatDate } from './utils';`
- `/Users/dev/project/src/auth/login.ts` -- `import { hashPassword } from '../utils';`
- `/Users/dev/project/src/api/users.ts` -- `import { sanitizeInput } from '../utils';`

The brains decomposes this into 6 grunt tasks:

1. SEARCH_REPORT to confirm which files import from utils
2. RENAME the file
3. EDIT each importing file (3 tasks)
4. VALIDATE that TypeScript compiles

---

## Task 1: Confirm Import References

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-201
- task_type: SEARCH_REPORT
- created_by: Claude
- created_at: 2026-02-27T11:00:00Z
- depends_on: none
- priority: 50
- batch_id: GB-2026-02-27-030

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project/src` exists

## OPERATION
- action: SEARCH_REPORT
- search_command: grep -rn "from.*['\"].*utils['\"]" /Users/dev/project/src/ --include="*.ts"
- shell: /bin/bash
- scope: /Users/dev/project/src/
- report_format: FULL_OUTPUT

## VALIDATION
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 2: Rename the File

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-202
- task_type: RENAME
- created_by: Claude
- created_at: 2026-02-27T11:00:00Z
- depends_on: GT-2026-02-27-201
- priority: 100
- batch_id: GB-2026-02-27-030

## TARGET
- file: /Users/dev/project/src/utils.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/utils.ts` exists
- [ ] File `/Users/dev/project/src/helpers.ts` does not exist

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

---

## Task 3: Update Import in app.ts

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-203
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T11:00:00Z
- depends_on: GT-2026-02-27-202
- priority: 200
- batch_id: GB-2026-02-27-030

## TARGET
- file: /Users/dev/project/src/app.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/app.ts` exists
- [ ] File `/Users/dev/project/src/app.ts` contains the exact string: `from './utils'`

## OPERATION
- action: EDIT
- find_exact: |
    ```typescript
    import { formatDate } from './utils';
    ```
- replace_with: |
    ```typescript
    import { formatDate } from './helpers';
    ```
- occurrence: ALL
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/app.ts` contains the exact string: `from './helpers'`
- [ ] File `/Users/dev/project/src/app.ts` does NOT contain the string: `from './utils'`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 4: Update Import in auth/login.ts

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-204
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T11:00:00Z
- depends_on: GT-2026-02-27-202
- priority: 200
- batch_id: GB-2026-02-27-030

## TARGET
- file: /Users/dev/project/src/auth/login.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/auth/login.ts` exists
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `from '../utils'`

## OPERATION
- action: EDIT
- find_exact: |
    ```typescript
    import { hashPassword } from '../utils';
    ```
- replace_with: |
    ```typescript
    import { hashPassword } from '../helpers';
    ```
- occurrence: ALL
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `from '../helpers'`
- [ ] File `/Users/dev/project/src/auth/login.ts` does NOT contain the string: `from '../utils'`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 5: Update Import in api/users.ts

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-205
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T11:00:00Z
- depends_on: GT-2026-02-27-202
- priority: 200
- batch_id: GB-2026-02-27-030

## TARGET
- file: /Users/dev/project/src/api/users.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/api/users.ts` exists
- [ ] File `/Users/dev/project/src/api/users.ts` contains the exact string: `from '../utils'`

## OPERATION
- action: EDIT
- find_exact: |
    ```typescript
    import { sanitizeInput } from '../utils';
    ```
- replace_with: |
    ```typescript
    import { sanitizeInput } from '../helpers';
    ```
- occurrence: ALL
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/api/users.ts` contains the exact string: `from '../helpers'`
- [ ] File `/Users/dev/project/src/api/users.ts` does NOT contain the string: `from '../utils'`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 6: Validate Compilation

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-206
- task_type: VALIDATE
- created_by: Claude
- created_at: 2026-02-27T11:00:00Z
- depends_on: GT-2026-02-27-203, GT-2026-02-27-204, GT-2026-02-27-205
- priority: 900
- batch_id: GB-2026-02-27-030

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project` exists
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
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Dependency Graph

```
GT-201 (SEARCH_REPORT: confirm imports)
  └── GT-202 (RENAME: utils.ts → helpers.ts)
        ├── GT-203 (EDIT: app.ts)
        ├── GT-204 (EDIT: auth/login.ts)
        └── GT-205 (EDIT: api/users.ts)
              └── GT-206 (VALIDATE: tsc --noEmit)
                    (depends on 203, 204, 205)
```

## Notes

- Tasks 203, 204, 205 can run in parallel -- they edit different files and all depend only on the RENAME completing.
- The SEARCH_REPORT (201) runs first so the brains can verify its assumptions. In practice, the brains already has this data and generates all tasks upfront, but including the search provides an audit trail.
- The VALIDATE (206) waits for ALL three edits to complete before checking compilation.
