# Example: Create a Configuration File

## Scenario

The brains needs to create a new database configuration file at `/Users/dev/project/config/database.json`. The `config/` directory does not exist yet.

The brains decomposes this into 4 grunt tasks:

1. RUN to create the directory
2. CREATE the JSON config file with exact content
3. VALIDATE the JSON is parseable
4. VALIDATE the required fields exist

---

## Task 1: Create the Config Directory

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-301
- task_type: RUN
- created_by: Claude
- created_at: 2026-02-27T13:00:00Z
- depends_on: none
- priority: 50
- batch_id: GB-2026-02-27-040

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] Directory `/Users/dev/project` exists

## OPERATION
- action: RUN
- command: mkdir -p /Users/dev/project/config
- shell: /bin/bash
- timeout_seconds: 10
- capture: both
- expected_exit_code: 0

## VALIDATION
- [ ] Directory `/Users/dev/project/config` exists

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 2: Create the Config File

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-302
- task_type: CREATE
- created_by: Claude
- created_at: 2026-02-27T13:00:00Z
- depends_on: GT-2026-02-27-301
- priority: 100
- batch_id: GB-2026-02-27-040

## TARGET
- file: /Users/dev/project/config/database.json
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/config/database.json` does not exist
- [ ] Directory `/Users/dev/project/config` exists

## OPERATION
- action: CREATE
- content: |
    ```json
    {
      "host": "localhost",
      "port": 5432,
      "database": "myapp_dev",
      "username": "postgres",
      "password": "",
      "ssl": false,
      "pool": {
        "min": 2,
        "max": 10,
        "idle_timeout_ms": 30000
      },
      "migrations": {
        "directory": "./migrations",
        "table_name": "schema_migrations"
      }
    }
    ```
- encoding: utf-8
- overwrite: false

## VALIDATION
- [ ] File `/Users/dev/project/config/database.json` exists and is non-empty
- [ ] File `/Users/dev/project/config/database.json` contains the exact string: `"host": "localhost"`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 3: Validate JSON Syntax

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-303
- task_type: VALIDATE
- created_by: Claude
- created_at: 2026-02-27T13:00:00Z
- depends_on: GT-2026-02-27-302
- priority: 800
- batch_id: GB-2026-02-27-040

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] File `/Users/dev/project/config/database.json` exists
- [ ] Command `node` is available in PATH

## OPERATION
- action: VALIDATE
- command: node -e "JSON.parse(require('fs').readFileSync('/Users/dev/project/config/database.json', 'utf8')); console.log('VALID_JSON');"
- shell: /bin/bash
- timeout_seconds: 10
- expected_exit_code: 0
- expected_stdout_contains: VALID_JSON
- expected_stdout_not_contains: SyntaxError

## VALIDATION
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Task 4: Validate Required Fields

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-304
- task_type: VALIDATE
- created_by: Claude
- created_at: 2026-02-27T13:00:00Z
- depends_on: GT-2026-02-27-302
- priority: 800
- batch_id: GB-2026-02-27-040

## TARGET
- file: N/A
- working_directory: /Users/dev/project

## PRECONDITIONS
- [ ] File `/Users/dev/project/config/database.json` exists
- [ ] Command `node` is available in PATH

## OPERATION
- action: VALIDATE
- command: node -e "const c=JSON.parse(require('fs').readFileSync('/Users/dev/project/config/database.json','utf8')); const required=['host','port','database','username']; const missing=required.filter(k=>!(k in c)); if(missing.length){console.log('MISSING:'+missing.join(','));process.exit(1);}console.log('ALL_FIELDS_PRESENT');"
- shell: /bin/bash
- timeout_seconds: 10
- expected_exit_code: 0
- expected_stdout_contains: ALL_FIELDS_PRESENT
- expected_stdout_not_contains: MISSING

## VALIDATION
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```

---

## Dependency Graph

```
GT-301 (RUN: mkdir config/)
  └── GT-302 (CREATE: database.json)
        ├── GT-303 (VALIDATE: JSON syntax)
        └── GT-304 (VALIDATE: required fields)
```

## Notes

- Tasks 303 and 304 can run in parallel -- they are both read-only validations on the same file.
- The brains provides the COMPLETE JSON content in Task 302. No placeholders, no "fill in your values" -- every character is specified.
- The validation commands use `node -e` for inline JavaScript, keeping the commands self-contained (no external scripts needed).
