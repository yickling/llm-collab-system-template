# Local Grunt Subsystem

A task execution protocol for small, locally-hosted LLMs (7b-20b parameters). A stronger LLM (the "brains") generates structured task definitions; grunts execute them mechanically. Grunts are not collaborators -- they are tools.

## Architecture

The brains LLM can dispatch tasks to grunts either **indirectly** (generating definitions for a human/script to dispatch) or **directly** (calling the local LLM API itself via shell access).

### Indirect Dispatch (human or runner in the middle)

```
┌─────────────────────────────────────┐
│            BRAINS LLM               │
│   (Claude, GPT-4, etc.)            │
│   - Reads codebase                  │
│   - Plans changes                   │
│   - Generates grunt tasks           │
│   - Reviews grunt results           │
│   - Makes ALL decisions             │
└──────────────┬──────────────────────┘
               │ Task Definitions (structured markdown)
               ▼
┌─────────────────────────────────────┐
│   Human / Runner Script             │
│   - Dispatches tasks to grunt       │
│   - Collects results                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│          GRUNT LLM(s)              │
│   (Llama 7B, Mistral 7B, etc.)    │
│   - Reads one task at a time        │
│   - Executes mechanically           │
│   - Reports results verbatim        │
│   - NEVER improvises                │
│   - STOPs on any ambiguity          │
└─────────────────────────────────────┘
```

### Direct Dispatch (brains calls grunt API via shell)

```
┌─────────────────────────────────────┐
│            BRAINS LLM               │
│   (Claude Code, Codex, Cursor)     │
│   - Reads codebase                  │
│   - Plans changes                   │
│   - Generates grunt task            │
│   - Calls dispatch-grunt.sh ◄────── shell access required
│   - Reads structured result         │
│   - Decides next steps              │
│   - Commits when all DONE           │
└──────────────┬──────────────────────┘
               │ curl → localhost:11434
               ▼
┌─────────────────────────────────────┐
│          GRUNT LLM                  │
│   (Ollama / LM Studio / vLLM)     │
│   - Receives system prompt + task   │
│   - Executes mechanically           │
│   - Returns structured result       │
└─────────────────────────────────────┘
```

**Direct dispatch requires**: The brains LLM must have shell/command execution access, and a local LLM server must be running on the same machine (or reachable via network). See [QUICKSTART.md](QUICKSTART.md) for setup.

## When to Use Grunts

Tasks that are purely mechanical:

- Exact string replacements in files
- Creating files from exact content
- Appending/inserting content at known locations
- Running specific commands and reporting output
- Searching for patterns and reporting results
- Validating expected state

## When NOT to Use Grunts

Anything requiring judgment:

- Writing new test logic
- Resolving merge conflicts
- Choosing between implementation approaches
- Interpreting error messages to decide next steps
- Writing code that requires understanding runtime behavior
- Refactoring or architectural decisions

## Relationship to the Collaboration Protocol

Grunts do **not** participate in `docs/memory/` handoffs. The brains LLM that dispatches grunt tasks is the actor of record. Grunt executions are logged as part of the brains' session, not as independent sessions. The brains is responsible for validating all grunt output before committing.

## File Map

| File | Purpose |
|------|---------|
| `README.md` | This file -- architecture overview |
| `GRUNT_SYSTEM_PROMPT.md` | System prompt fed to grunt LLMs at every invocation |
| `CONSTRAINTS.md` | Rules the brains must follow when generating tasks |
| `TASK_FORMAT.md` | Canonical task definition envelope format |
| `task-types/README.md` | Index of all task types |
| `task-types/EDIT.md` | Exact string replacement |
| `task-types/CREATE.md` | Write new file with exact content |
| `task-types/APPEND.md` | Add content to end of file |
| `task-types/INSERT.md` | Insert content at specific location |
| `task-types/DELETE.md` | Remove a file |
| `task-types/RENAME.md` | Move or rename a file |
| `task-types/RUN.md` | Execute a command, report output |
| `task-types/VALIDATE.md` | Run command, check expected output |
| `task-types/SEARCH_REPORT.md` | Find pattern, report results (read-only) |
| `examples/README.md` | Index of worked examples |
| `examples/add-logging-to-module.md` | Multi-task: add logging to existing module |
| `examples/rename-and-update-imports.md` | Multi-task: rename file + update imports |
| `examples/create-config-file.md` | Multi-task: create config + validate |
| `examples/search-and-replace-pattern.md` | Multi-task: find pattern, bulk replace |
| `../scripts/dispatch-grunt.sh` | Dispatch script (Ollama + OpenAI-compatible APIs) |

## Workflow

1. **Brains reads codebase** and determines what needs to change.
2. **Brains decomposes** the change into atomic grunt tasks following `CONSTRAINTS.md`.
3. **Brains generates** task definitions in `TASK_FORMAT.md` format.
4. **Runner dispatches** tasks to grunt LLMs, respecting `depends_on` ordering.
5. **Grunt executes** each task mechanically, reports DONE/BLOCKED/FAILED.
6. **Brains reviews** results, handles failures, and commits successful changes.

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for step-by-step setup instructions, including installing a local LLM, running your first grunt task, and wiring up your brains LLM.

For the full human developer guide (cost analysis, optimization strategies, troubleshooting), see [LOCAL_GRUNT_GUIDE.md](../LOCAL_GRUNT_GUIDE.md).

## Brains Integration Patterns

Any LLM acting as a "brains" can generate grunt tasks. There are two modes:

| Mode | How it works | Requires |
|------|-------------|----------|
| **Indirect** | Brains outputs task definitions; human or script dispatches them | Nothing special |
| **Direct** | Brains calls `dispatch-grunt.sh` via shell and reads the result | Shell access + local LLM server running |

Direct dispatch is the fully autonomous mode -- the brains generates a task, dispatches it, reads the result, and acts on it in a closed loop. No human intervention needed.

### Preconditions for Direct Dispatch

1. **Local LLM server running** -- Ollama, LM Studio, llama.cpp, or vLLM serving a model on localhost.
2. **Brains has shell access** -- Claude Code (`Bash` tool), Codex (sandbox shell), Cursor (terminal).
3. **`jq` installed** -- The dispatch script uses `jq` for JSON handling (`brew install jq` or `apt install jq`).
4. **`scripts/dispatch-grunt.sh` exists** -- The dispatch script in this repo.

Test that the preconditions are met:

```bash
# Check Ollama is running
curl -s http://localhost:11434/api/tags | jq '.models[].name'

# Check dispatch script is executable
./scripts/dispatch-grunt.sh --help

# Test with a trivial task
echo '# GRUNT TASK
## METADATA
- task_id: GT-TEST-001
- task_type: RUN
- created_by: test
- created_at: 2026-01-01T00:00:00Z
- depends_on: none
## TARGET
- file: N/A
- working_directory: /tmp
## PRECONDITIONS
- [ ] Directory `/tmp` exists
## OPERATION
- action: RUN
- command: echo "grunt works"
- shell: /bin/bash
- timeout_seconds: 10
- capture: stdout
- expected_exit_code: 0
## VALIDATION
- not_applicable
## ROLLBACK
- On failure: STOP_AND_REPORT' | ./scripts/dispatch-grunt.sh -
```

### Claude Code (Direct Dispatch)

Add to `CLAUDE.md`:

```markdown
## Local Grunt Protocol

This project supports offloading mechanical tasks to a locally-hosted small LLM.
Read `local-grunt/README.md` for the architecture.

### When to use grunts
When you identify purely mechanical work (exact string replacements, file creation
from specified content, running commands), dispatch it to the local grunt LLM
instead of performing it yourself. This saves API costs.

### How to dispatch directly
1. Generate a task definition following `local-grunt/TASK_FORMAT.md` and the
   relevant `local-grunt/task-types/` spec.
2. Write the task to a temp file or pass it inline to the dispatch script.
3. Call: `./scripts/dispatch-grunt.sh --inline "<task definition>"`
   Or:   `./scripts/dispatch-grunt.sh /path/to/task.md`
4. Read the structured result (DONE / BLOCKED / FAILED).
5. If DONE, verify the change. If BLOCKED/FAILED, investigate and retry.

### Constraints
Follow `local-grunt/CONSTRAINTS.md` when decomposing work.
See `local-grunt/examples/` for complete multi-task decomposition examples.

### Environment
- Grunt server: Ollama on localhost:11434
- Model: qwen2.5-coder:7b-instruct
- Dispatch script: ./scripts/dispatch-grunt.sh
```

**Example -- Claude Code dispatching a grunt task directly:**

```bash
# Claude Code generates a task and dispatches it in one step
./scripts/dispatch-grunt.sh --inline '# GRUNT TASK

## METADATA
- task_id: GT-2026-02-27-001
- task_type: EDIT
- created_by: Claude
- created_at: 2026-02-27T10:00:00Z
- depends_on: none
- priority: 100
- batch_id: GB-2026-02-27-001

## TARGET
- file: /Users/dev/project/src/config.ts
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/Users/dev/project/src/config.ts` exists
- [ ] File `/Users/dev/project/src/config.ts` contains the exact string: `"version": "1.2.3"`

## OPERATION
- action: EDIT
- find_exact: |
    ```typescript
      version: "1.2.3",
    ```
- replace_with: |
    ```typescript
      version: "1.3.0",
    ```
- occurrence: FIRST
- expected_match_count: 1

## VALIDATION
- [ ] File `/Users/dev/project/src/config.ts` contains the exact string: `version: "1.3.0"`

## ROLLBACK
- On failure: STOP_AND_REPORT'
```

Claude Code reads the result, checks for `status: DONE`, and proceeds.

### OpenAI Codex (Direct Dispatch)

Add to `AGENTS.md`:

```markdown
## Grunt Task Dispatch

When work is purely mechanical, dispatch it to the local grunt LLM.

To dispatch:
  ./scripts/dispatch-grunt.sh /path/to/task.md
  # or inline:
  ./scripts/dispatch-grunt.sh --inline "<task markdown>"

Follow the format in local-grunt/TASK_FORMAT.md and local-grunt/task-types/.

Rules (from local-grunt/CONSTRAINTS.md):
- One operation per task
- All context inline (absolute paths, exact strings)
- Include validation steps for every modifying task
- Maximum 4000 tokens per task definition

Read the result. If status is DONE, verify the change.
If BLOCKED or FAILED, investigate and regenerate.
```

### Cursor / Antigravity (Direct Dispatch)

Add to `.cursorrules`:

```markdown
This project has a local grunt protocol in local-grunt/.
For mechanical tasks, dispatch them to the local grunt LLM by running:
  ./scripts/dispatch-grunt.sh --inline "<task definition>"
Follow local-grunt/TASK_FORMAT.md for format. Read the result for status.
```

### Indirect Mode (Any Agent Without Shell Access)

If the brains LLM does not have shell access, it outputs task definitions for a human or runner script to dispatch. Include in your system prompt:

```
You can generate task definitions for a local grunt LLM to execute mechanical work.
Read local-grunt/TASK_FORMAT.md for the format. Read local-grunt/CONSTRAINTS.md
for the rules. Each task must be self-contained with absolute paths, exact strings,
and validation steps. Output the task definitions and the human will dispatch them.
```

### How the Brains Should Handle Results

When grunt results come back, the brains should:

1. **DONE**: The change was applied. Verify by reading the modified file or running a broader validation.
2. **BLOCKED**: The task definition was wrong (file changed, string not found, precondition failed). Re-read the source file and regenerate the task with updated content.
3. **FAILED**: The operation ran but produced unexpected results. Investigate the `error_output` field. The brains may need to take a different approach entirely.

If more than 30% of tasks in a batch return BLOCKED or FAILED, the brains should stop, re-examine the source files, and regenerate the entire batch. The decomposition was likely based on stale information.
