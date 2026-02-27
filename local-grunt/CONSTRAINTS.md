# Brains Constraints

Rules the brains LLM **must** follow when generating grunt tasks. This is the quality control document. A well-specified task succeeds even with a weak grunt. A poorly-specified task fails even with a strong grunt.

## The Golden Rule

**If you (the brains) would need to "think about it" to execute a task, the grunt definitely cannot do it. Decompose further.**

## Task Decomposition Rules

### 1. One Operation per Task

A task does ONE thing: one file edit, one file creation, one command execution. Never combine operations.

**Wrong**: "Edit file A and then run tests"
**Right**: Task 1 = EDIT file A, Task 2 = VALIDATE (run tests, depends_on Task 1)

### 2. All Context Inline

The grunt cannot read external documentation. Every piece of information needed must be in the task body.

**Wrong**: "Replace the function signature as described in PROTOCOL.md"
**Right**: Provide the exact `find_exact` string and `replace_with` string in the task.

### 3. No Relative References

Use absolute file paths always.

**Wrong**: `./src/auth.ts`, `the file we discussed earlier`
**Right**: `/Users/dev/project/src/auth.ts`

### 4. Exact Strings, Never Patterns

For EDIT tasks, provide the literal exact string to find, character-for-character.

**Wrong**: "Find the function that handles authentication"
**Right**: Provide the exact 5 lines of code that constitute the function signature and opening.

### 5. Bounded Scope

A task touches at most ONE file (except RENAME which has source and destination). Multi-file changes become multiple tasks.

### 6. Include Verification

Every task that modifies state must have a `VALIDATION` section. The grunt runs this check after execution.

### 7. Sequence Explicitly

If tasks depend on each other, use `depends_on` fields. The runner enforces ordering. Never assume execution order.

### 8. Escape Code Properly

Code content must be inside fenced code blocks with language identifiers. Indentation must be exact.

## Context Packaging Rules

### For EDIT Tasks

- Include at least 3 lines of surrounding context above and below the target string in `find_exact`.
- The extra context ensures the grunt matches the right location, not a similar string elsewhere.
- Always set `expected_match_count` to the exact number of times the string appears.

### For INSERT Tasks

- The `insert_after` anchor must be a unique string in the file.
- Include surrounding lines so the grunt can verify it found the correct location.
- Set `expected_match_count: 1` unless you specifically need to handle multiple anchors.

### For CREATE Tasks

- Provide the COMPLETE file content. No placeholders, no `TODO`, no `...` ellipsis.
- Every character the file should contain must be in the `content` field.

### For RUN / VALIDATE Tasks

- Provide the exact command, the working directory, and the expected output or exit code.
- If the command has environment requirements, state them as preconditions.

## What Brains Must NOT Delegate to Grunts

- Writing new test logic (grunts can *run* tests, not *write* them)
- Resolving merge conflicts
- Choosing between implementation approaches
- Interpreting error messages to decide next steps
- Writing code that requires understanding runtime behavior
- Any "figure out what to do" task
- Modifying code where the correct output depends on understanding program state
- Refactoring (requires understanding relationships between code)
- Debugging (requires reasoning about cause and effect)

## Size Limits

| Limit | Value | Rationale |
|-------|-------|-----------|
| Max tokens per task | 4,000 | Fits small model context windows (2048-8192 tokens) |
| Max lines in a `content` field | 200 | Prevents grunt from losing track of large blocks |
| Max tasks in a batch | 20 | Keeps orchestration manageable |
| Max files touched per task | 1 | Enforces atomic scope (except RENAME: 2) |

## Error Budget

If a grunt returns BLOCKED or FAILED on more than 30% of tasks in a batch, the brains must:

1. **Stop dispatching** remaining tasks in the batch.
2. **Analyze** the failure pattern -- are tasks under-specified? Are preconditions wrong?
3. **Re-examine** the source files (they may have changed since task generation).
4. **Re-decompose** with better context packaging.

A high failure rate means the brains is generating tasks that are too complex or contain stale information. Fix the decomposition, not the grunt.

## Quality Checklist for Generated Tasks

Before dispatching a batch, the brains should verify:

- [ ] Every task has a unique `task_id`
- [ ] Every `depends_on` reference points to a real task_id in the batch
- [ ] No circular dependencies
- [ ] Every file path is absolute
- [ ] Every EDIT task has `expected_match_count` set
- [ ] Every modifying task has at least one VALIDATION step
- [ ] No task exceeds 4,000 tokens
- [ ] No `content` field exceeds 200 lines
- [ ] Batch has 20 or fewer tasks
- [ ] No task requires judgment or interpretation
