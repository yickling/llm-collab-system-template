# Local Grunt Subsystem

A task execution protocol for small, locally-hosted LLMs (7b-20b parameters). A stronger LLM (the "brains") generates structured task definitions; grunts execute them mechanically. Grunts are not collaborators -- they are tools.

## Architecture

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
│          GRUNT LLM(s)              │
│   (Llama 7B, Mistral 7B, etc.)    │
│   - Reads one task at a time        │
│   - Executes mechanically           │
│   - Reports results verbatim        │
│   - NEVER improvises                │
│   - STOPs on any ambiguity          │
└─────────────────────────────────────┘
```

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

Any LLM acting as a "brains" can generate grunt tasks. Here is how to enable each agent:

### Claude Code

Add to `CLAUDE.md`:

```markdown
## Local Grunt Protocol

This project supports offloading mechanical tasks to locally-hosted small LLMs.
Read `local-grunt/README.md` for the architecture.

When you identify purely mechanical work (exact string replacements, file creation
from specified content, running commands), generate grunt task definitions following
`local-grunt/TASK_FORMAT.md` and the relevant `local-grunt/task-types/` spec.

Follow `local-grunt/CONSTRAINTS.md` when decomposing work into tasks.
See `local-grunt/examples/` for complete worked examples.

Output task definitions so the human (or a runner script) can dispatch them
to the local grunt LLM. Do NOT execute grunt tasks yourself -- generate the
definitions and let the grunt handle execution.
```

### OpenAI Codex

Add to `AGENTS.md`:

```markdown
## Grunt Task Generation

When work is purely mechanical, generate grunt task definitions instead of
performing the changes directly. Follow the format in local-grunt/TASK_FORMAT.md
and the operation specs in local-grunt/task-types/.

Rules (from local-grunt/CONSTRAINTS.md):
- One operation per task
- All context inline (absolute paths, exact strings)
- Include validation steps for every modifying task
- Maximum 4000 tokens per task definition
```

### Cursor / Antigravity

Add to `.cursorrules`:

```markdown
This project has a local grunt protocol in local-grunt/.
For mechanical tasks (string replacements, file creation, command execution),
generate structured grunt task definitions following local-grunt/TASK_FORMAT.md
instead of performing the changes. The human will dispatch them to a local LLM.
```

### Any LLM Agent (Generic)

Include in your system prompt:

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
