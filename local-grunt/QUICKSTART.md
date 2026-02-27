# Quick Start

Get the grunt protocol running in your project in 5 minutes.

## Step 1: Copy the `local-grunt/` directory into your project

```bash
# From the template repo
cp -r llm-collab-system-template/local-grunt/ your-project/local-grunt/
```

Your project should now have:

```
your-project/
├── local-grunt/
│   ├── README.md
│   ├── GRUNT_SYSTEM_PROMPT.md
│   ├── CONSTRAINTS.md
│   ├── TASK_FORMAT.md
│   ├── task-types/
│   └── examples/
└── (your existing code)
```

## Step 2: Install a local LLM

The fastest path is Ollama:

```bash
# Install
curl -fsSL https://ollama.ai/install.sh | sh   # Linux/Mac
# or download from https://ollama.ai for Windows

# Pull a code-focused model
ollama pull qwen2.5-coder:7b-instruct

# Verify it works
ollama run qwen2.5-coder:7b-instruct "What is 2+2?"
```

## Step 3: Run your first grunt task

Create a test task file `test-task.md`:

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-TEST-001
- task_type: RUN
- created_by: Human
- created_at: 2026-01-01T00:00:00Z
- depends_on: none
- priority: 500
- batch_id: GB-TEST-001

## TARGET
- file: N/A
- working_directory: /tmp

## PRECONDITIONS
- [ ] Directory `/tmp` exists

## OPERATION
- action: RUN
- command: echo "Hello from grunt"
- shell: /bin/bash
- timeout_seconds: 10
- capture: stdout
- expected_exit_code: 0

## VALIDATION
- not_applicable

## ROLLBACK
- On failure: STOP_AND_REPORT
```

Send it to your grunt:

```bash
# Extract the system prompt (between the BEGIN/END markers)
SYSTEM_PROMPT=$(sed -n '/## BEGIN SYSTEM PROMPT/,/## END SYSTEM PROMPT/p' local-grunt/GRUNT_SYSTEM_PROMPT.md)

# Dispatch to Ollama
ollama run qwen2.5-coder:7b-instruct \
  --system "$SYSTEM_PROMPT" \
  "$(cat test-task.md)"
```

You should get a structured result like:

```
## RESULT
- task_id: GT-TEST-001
- status: DONE
- details: Hello from grunt
- files_modified: none
- validation_passed: not_applicable
```

## Step 4: Try a real task

Create a file to edit:

```bash
echo 'const greeting = "hello world";' > /tmp/test-file.js
```

Create an EDIT task:

```markdown
# GRUNT TASK

## METADATA
- task_id: GT-TEST-002
- task_type: EDIT
- created_by: Human
- created_at: 2026-01-01T00:00:00Z
- depends_on: none
- priority: 500
- batch_id: GB-TEST-001

## TARGET
- file: /tmp/test-file.js
- working_directory: N/A

## PRECONDITIONS
- [ ] File `/tmp/test-file.js` exists
- [ ] File `/tmp/test-file.js` contains the exact string: `const greeting = "hello world";`

## OPERATION
- action: EDIT
- find_exact: |
    ```javascript
    const greeting = "hello world";
    ```
- replace_with: |
    ```javascript
    const greeting = "hello grunt";
    ```
- occurrence: FIRST
- expected_match_count: 1

## VALIDATION
- [ ] File `/tmp/test-file.js` contains the exact string: `const greeting = "hello grunt";`
- [ ] File `/tmp/test-file.js` does NOT contain the string: `hello world`

## ROLLBACK
- On failure: STOP_AND_REPORT
```

## Step 5: Wire up your brains LLM

Tell your brains LLM about the grunt protocol by adding this to its system instructions (CLAUDE.md, AGENTS.md, .cursorrules, etc.):

```markdown
## Local Grunt Protocol

This project uses a local grunt protocol for mechanical tasks.
Read `local-grunt/README.md` for the architecture overview.

When you identify tasks that are purely mechanical (exact string replacements,
file creation from exact content, running commands), you can generate grunt
task definitions instead of performing them directly. This saves API costs
by offloading work to locally-hosted small LLMs.

To generate grunt tasks:
1. Read `local-grunt/TASK_FORMAT.md` for the canonical envelope format.
2. Read the relevant `local-grunt/task-types/` file for the operation format.
3. Follow `local-grunt/CONSTRAINTS.md` when decomposing work.
4. Generate task definitions that the human or a runner script will dispatch.

See `local-grunt/examples/` for complete multi-task decomposition examples.
```

## Step 6: Generate tasks from your brains LLM

Ask your brains LLM to decompose a change into grunt tasks. For example:

> "I need to rename the function `getUser` to `fetchUser` across the codebase. Generate grunt task definitions for this change following `local-grunt/TASK_FORMAT.md`."

The brains will:
1. Read the relevant files to find all occurrences
2. Generate a SEARCH_REPORT task to confirm locations
3. Generate EDIT tasks for each file (with exact `find_exact`/`replace_with` strings)
4. Generate a VALIDATE task to confirm compilation

You then dispatch these to your local grunt LLM.

---

## Next Steps

- Read [LOCAL_GRUNT_GUIDE.md](../LOCAL_GRUNT_GUIDE.md) for the full human developer guide, including cost optimization and troubleshooting.
- Read [CONSTRAINTS.md](CONSTRAINTS.md) to understand what makes a good grunt task.
- Browse [examples/](examples/) for complete worked decompositions.
- Read the [Brains Integration](#brains-integration-patterns) section in the main README for agent-specific setup.

## Common Setups

### Solo developer with Claude Code + local grunt

```
You ──► Claude Code (brains) ──► generates task definitions
                                        │
        You dispatch tasks ◄────────────┘
                │
                ▼
        Ollama (grunt) ──► executes tasks ──► you review results
                                                      │
        Claude Code reviews / commits ◄───────────────┘
```

1. Use Claude Code as your brains for planning and task generation.
2. When Claude identifies mechanical work, ask it to output grunt task definitions.
3. Run the tasks through your local Ollama instance.
4. Feed results back to Claude Code for review and commit.

### CI pipeline with API brains + local grunt runner

```
CI trigger ──► API call to Claude (brains) ──► task definitions
                                                      │
              Grunt runner script ◄───────────────────┘
                │
                ▼
              Local LLM (grunt) ──► results ──► API call to Claude (review)
                                                      │
              Auto-commit if all DONE ◄───────────────┘
```

1. CI event triggers a brains API call with the change request.
2. Brains returns a batch of grunt task definitions.
3. Runner script dispatches tasks to a local LLM server.
4. Results are collected and sent back to brains for review.
5. If all tasks pass, changes are committed automatically.

### Team with multiple agents + shared grunt pool

```
Claude Code ──┐
Codex ────────┼──► Shared task queue ──► Grunt LLM pool (2-4 instances)
Cursor ───────┘                                  │
                                                 ▼
                                         Results collected
                                                 │
              Brains agents review ◄─────────────┘
```

1. Multiple brains agents generate tasks into a shared queue (directory or message queue).
2. A pool of grunt LLM instances picks up tasks.
3. Results are routed back to the originating brains agent.
4. Each brains agent reviews its own grunt results.
