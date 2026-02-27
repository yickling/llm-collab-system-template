# Grunt Task Format

Every grunt task uses this canonical envelope format. Type-specific fields in the OPERATION section are documented in `task-types/`.

## Template

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-YYYY-MM-DD-NNN
- task_type: EDIT | CREATE | APPEND | INSERT | DELETE | RENAME | RUN | VALIDATE | SEARCH_REPORT
- created_by: (brains LLM name)
- created_at: (UTC ISO 8601 timestamp)
- depends_on: (comma-separated task_ids, or "none")
- priority: (integer 1-999, lower = higher priority)
- batch_id: GB-YYYY-MM-DD-NNN

## TARGET
- file: (absolute path, or "N/A" for RUN/VALIDATE/SEARCH_REPORT)
- working_directory: (absolute path for commands, or "N/A")

## PRECONDITIONS
(Checkboxes. The grunt checks ALL before proceeding. If ANY fails, report BLOCKED.)

- [ ] (precondition 1)
- [ ] (precondition 2)

## OPERATION
(Type-specific. See task-types/ for the exact format.)

## VALIDATION
(Checkboxes. The grunt runs ALL after the operation. If ANY fails, follow ROLLBACK.)

- [ ] (validation step 1)
- [ ] (validation step 2)

## ROLLBACK
- On failure: STOP_AND_REPORT | (specific rollback steps)
```

## Field Reference

| Field | Required | Format | Description |
|-------|----------|--------|-------------|
| `task_id` | Yes | `GT-YYYY-MM-DD-NNN` | Globally unique. The grunt copies this into its result. |
| `task_type` | Yes | One of 9 types | Must match exactly one defined type. |
| `created_by` | Yes | String | The brains LLM identity. Links to the audit trail. |
| `created_at` | Yes | ISO 8601 UTC | When the brains generated this task. |
| `depends_on` | Yes | Task IDs or "none" | Tasks that must complete with DONE before this runs. Enforced by the runner, not the grunt. |
| `priority` | No | Integer 1-999 | For ordering independent tasks. Default: 500. |
| `batch_id` | No | `GB-YYYY-MM-DD-NNN` | Groups tasks from a single decomposition. |
| `file` | Depends | Absolute path | Required for EDIT, CREATE, APPEND, INSERT, DELETE, RENAME. "N/A" for RUN, VALIDATE, SEARCH_REPORT. |
| `working_directory` | Depends | Absolute path | Required for RUN, VALIDATE, SEARCH_REPORT. "N/A" for file operations. |

## Precondition Patterns

Common preconditions to use:

```markdown
- [ ] File `/absolute/path/to/file.ts` exists
- [ ] File `/absolute/path/to/file.ts` does not exist
- [ ] Directory `/absolute/path/to/dir` exists
- [ ] File `/absolute/path/to/file.ts` contains the exact string: `first 40 chars...`
- [ ] Command `node --version` is available in PATH
```

## Validation Patterns

Common validation steps:

```markdown
- [ ] File `/absolute/path/to/file.ts` contains the exact string: `expected content...`
- [ ] File `/absolute/path/to/file.ts` does NOT contain the string: `old content...`
- [ ] Command: `grep -c "pattern" /absolute/path/to/file.ts` outputs `1`
- [ ] Command: `npx tsc --noEmit` exits with code 0
- [ ] File `/absolute/path/to/new-file.ts` exists and is non-empty
```

## Rules

1. All paths must be **absolute**. Never use `./relative/path`.
2. All string matches are **case-sensitive** and **whitespace-sensitive**.
3. Code content in OPERATION must use fenced code blocks with language identifiers.
4. Indentation in code blocks must be **exact** -- the grunt reproduces it character-for-character.
5. The grunt must not infer or assume anything not explicitly stated in the task.
6. One task = one operation. Never combine multiple operations in a single task.
