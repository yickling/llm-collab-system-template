# Example: Add Logging to Auth Module

## Scenario

The brains needs to add a logging import and logging calls to `/Users/dev/project/src/auth/login.ts`. The file currently looks like this:

```typescript
import { db } from '../db';
import { validateCredentials } from './validators';
import { User, Credentials } from './types';

export async function login(credentials: Credentials): Promise<User> {
  const valid = await validateCredentials(credentials);
  if (!valid) {
    throw new Error('Invalid credentials');
  }
  const result = await db.query('SELECT * FROM users WHERE username = $1', [credentials.username]);
  return result.rows[0];
}
```

The brains decomposes this into 3 grunt tasks:

1. INSERT the logging import after the last existing import
2. EDIT the function body to add logging calls
3. VALIDATE that TypeScript still compiles

---

## Task 1: Insert the Logging Import

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-101
- task_type: INSERT
- created_by: Claude
- created_at: 2026-02-27T10:00:00Z
- depends_on: none
- priority: 100
- batch_id: GB-2026-02-27-020

## TARGET
- file: /Users/dev/project/src/auth/login.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/auth/login.ts` exists
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `import { User, Credentials } from './typ`

## OPERATION
- action: INSERT
- insert_after: |
    ```typescript
    import { User, Credentials } from './types';
    ```
- content: |
    ```typescript
    import { createLogger } from '../utils/logger';

    const logger = createLogger('auth:login');
    ```
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `import { createLogger } from '../utils/logger';`
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `const logger = createLogger('auth:login');`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 2: Add Logging Calls to the Function

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-102
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T10:00:00Z
- depends_on: GT-2026-02-27-101
- priority: 200
- batch_id: GB-2026-02-27-020

## TARGET
- file: /Users/dev/project/src/auth/login.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/auth/login.ts` exists
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `export async function login(credentials:`

## OPERATION
- action: EDIT
- find_exact: |
    ```typescript
    export async function login(credentials: Credentials): Promise<User> {
      const valid = await validateCredentials(credentials);
      if (!valid) {
        throw new Error('Invalid credentials');
      }
      const result = await db.query('SELECT * FROM users WHERE username = $1', [credentials.username]);
      return result.rows[0];
    }
    ```
- replace_with: |
    ```typescript
    export async function login(credentials: Credentials): Promise<User> {
      logger.info('login attempt', { username: credentials.username });
      const valid = await validateCredentials(credentials);
      if (!valid) {
        logger.warn('login failed: invalid credentials', { username: credentials.username });
        throw new Error('Invalid credentials');
      }
      const result = await db.query('SELECT * FROM users WHERE username = $1', [credentials.username]);
      logger.info('login successful', { username: credentials.username });
      return result.rows[0];
    }
    ```
- occurrence: ALL
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `logger.info('login attempt'`
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `logger.warn('login failed: invalid credentials'`
- [ ] File `/Users/dev/project/src/auth/login.ts` contains the exact string: `logger.info('login successful'`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 3: Validate TypeScript Compilation

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-103
- task_type: VALIDATE
- created_by: Claude
- created_at: 2026-02-27T10:00:00Z
- depends_on: GT-2026-02-27-102
- priority: 900
- batch_id: GB-2026-02-27-020

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
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Dependency Graph

```
GT-101 (INSERT import)
  └── GT-102 (EDIT function body)
        └── GT-103 (VALIDATE compilation)
```

## Notes

- Task 102 depends on 101 because the INSERT changes the file content, and the EDIT's `find_exact` targets the original function body (which hasn't changed). If the EDIT ran first, the INSERT might shift line positions.
- The brains included the full function body in `find_exact` (8 lines) to ensure unique matching.
- The VALIDATE task is last because it checks the final state after all edits.
