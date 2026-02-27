# Task Type: CREATE

Create a new file with exact specified content.

## OPERATION Format

```markdown
## OPERATION
- action: CREATE
- content: |
    ```<language>
    (COMPLETE file content -- every character)
    ```
- encoding: utf-8
- overwrite: true | false
```

## Field Details

| Field | Required | Description |
|-------|----------|-------------|
| `content` | Yes | The ENTIRE file content. No placeholders, no `TODO`, no `...` ellipsis. |
| `encoding` | No | File encoding. Default: `utf-8`. |
| `overwrite` | Yes | If `false` and the file exists, report BLOCKED. If `true`, overwrite. |

## Rules

1. `content` must contain the COMPLETE file. Every character the file should have.
2. If `overwrite` is `false`, the precondition must include `File <path> does not exist`.
3. If the parent directory does not exist, the grunt creates it. The brains should include `Directory <parent> exists` as a precondition or generate a prior RUN task to create it.
4. After writing, the grunt verifies the file exists and is non-empty.

## Required Preconditions

For `overwrite: false`:
- `File <path> does not exist`
- `Directory <parent> exists`

For `overwrite: true`:
- `Directory <parent> exists`

## Example 1: Create a .gitignore File

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-020
- task_type: CREATE
- created_by: Claude
- created_at: 2026-02-27T12:00:00Z
- depends_on: none
- priority: 100
- batch_id: GB-2026-02-27-004

## TARGET
- file: /Users/dev/project/.gitignore
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/.gitignore` does not exist
- [ ] Directory `/Users/dev/project` exists

## OPERATION
- action: CREATE
- content: |
    ```text
    node_modules/
    dist/
    .env
    .env.local
    *.log
    .DS_Store
    coverage/
    ```
- encoding: utf-8
- overwrite: false

## VALIDATION
- [ ] File `/Users/dev/project/.gitignore` exists and is non-empty
- [ ] File `/Users/dev/project/.gitignore` contains the exact string: `node_modules/`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Example 2: Create a TypeScript Module

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-021
- task_type: CREATE
- created_by: Claude
- created_at: 2026-02-27T12:05:00Z
- depends_on: GT-2026-02-27-019
- priority: 200
- batch_id: GB-2026-02-27-004

## TARGET
- file: /Users/dev/project/src/utils/logger.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/utils/logger.ts` does not exist
- [ ] Directory `/Users/dev/project/src/utils` exists

## OPERATION
- action: CREATE
- content: |
    ```typescript
    export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

    export interface Logger {
      debug(message: string, context?: Record<string, unknown>): void;
      info(message: string, context?: Record<string, unknown>): void;
      warn(message: string, context?: Record<string, unknown>): void;
      error(message: string, context?: Record<string, unknown>): void;
    }

    export function createLogger(name: string): Logger {
      const log = (level: LogLevel, message: string, context?: Record<string, unknown>) => {
        const timestamp = new Date().toISOString();
        const entry = { timestamp, level, name, message, ...context };
        console.log(JSON.stringify(entry));
      };

      return {
        debug: (msg, ctx) => log('debug', msg, ctx),
        info: (msg, ctx) => log('info', msg, ctx),
        warn: (msg, ctx) => log('warn', msg, ctx),
        error: (msg, ctx) => log('error', msg, ctx),
      };
    }
    ```
- encoding: utf-8
- overwrite: false

## VALIDATION
- [ ] File `/Users/dev/project/src/utils/logger.ts` exists and is non-empty
- [ ] File `/Users/dev/project/src/utils/logger.ts` contains the exact string: `export function createLogger(name: string): Logger`

## ROLLBACK
- On failure: STOP_AND_REPORT
```
