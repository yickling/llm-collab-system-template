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

## Step 5: Install the dispatch script

The repo includes a dispatch script that handles API calls to your local LLM:

```bash
# Verify it's executable
chmod +x scripts/dispatch-grunt.sh

# Check dependencies (jq is required)
jq --version || echo "Install jq: brew install jq (Mac) or apt install jq (Linux)"

# Test it (Ollama must be running)
echo '# GRUNT TASK
## METADATA
- task_id: GT-TEST-DISPATCH
- task_type: RUN
- created_by: Human
- created_at: 2026-01-01T00:00:00Z
- depends_on: none
## TARGET
- file: N/A
- working_directory: /tmp
## PRECONDITIONS
- [ ] Directory `/tmp` exists
## OPERATION
- action: RUN
- command: echo "dispatch works"
- shell: /bin/bash
- timeout_seconds: 10
- capture: stdout
- expected_exit_code: 0
## VALIDATION
- not_applicable
## ROLLBACK
- On failure: STOP_AND_REPORT' | ./scripts/dispatch-grunt.sh -
```

The script supports Ollama (default) and OpenAI-compatible APIs (LM Studio, llama.cpp, vLLM):

```bash
# Ollama (default)
./scripts/dispatch-grunt.sh task.md

# LM Studio
GRUNT_PROVIDER=openai-compat GRUNT_API_URL=http://localhost:1234/v1 \
  ./scripts/dispatch-grunt.sh task.md

# Different model
GRUNT_MODEL=llama3.1:8b ./scripts/dispatch-grunt.sh task.md
```

## Step 6: Wire up your brains LLM

You have two options:

### Option A: Direct Dispatch (Recommended -- Fully Autonomous)

If your brains LLM has shell access (Claude Code, Codex, Cursor), it can dispatch tasks directly and read the results in a closed loop. No human in the middle.

Add to your agent config (e.g., `CLAUDE.md`):

```markdown
## Local Grunt Protocol

This project supports offloading mechanical tasks to a locally-hosted small LLM.
Read `local-grunt/README.md` for the architecture.

### When to use grunts
When you identify purely mechanical work (exact string replacements, file creation
from specified content, running commands), dispatch it to the local grunt LLM
instead of performing it yourself.

### How to dispatch directly
1. Generate a task definition following `local-grunt/TASK_FORMAT.md`.
2. Call: `./scripts/dispatch-grunt.sh --inline "<task definition>"`
3. Read the structured result (DONE / BLOCKED / FAILED).
4. If DONE, verify the change. If BLOCKED/FAILED, investigate and retry.

Follow `local-grunt/CONSTRAINTS.md` when decomposing work.
Grunt server: Ollama on localhost:11434, model: qwen2.5-coder:7b-instruct
```

**Preconditions for direct dispatch:**
- Local LLM server running (e.g., `ollama serve`)
- `jq` installed
- `scripts/dispatch-grunt.sh` executable

### Option B: Indirect Dispatch (Human Dispatches)

If the brains doesn't have shell access, it generates task definitions and you dispatch them manually.

Add to your agent config:

```markdown
## Local Grunt Protocol

This project uses a local grunt protocol for mechanical tasks.
Read `local-grunt/README.md` for the architecture overview.

When you identify purely mechanical work, generate grunt task definitions
following `local-grunt/TASK_FORMAT.md`. Output the definitions so the human
can dispatch them via: ./scripts/dispatch-grunt.sh task.md
```

## Step 7: Generate and dispatch tasks

### Direct dispatch example (Claude Code)

Ask Claude Code:

> "Rename the function `getUser` to `fetchUser` across the codebase. Use the grunt protocol to dispatch the mechanical edits."

Claude Code will:
1. Read the relevant files to find all occurrences
2. Generate a task definition for each file
3. Call `./scripts/dispatch-grunt.sh --inline "<task>"` for each
4. Read results, handle any BLOCKED/FAILED cases
5. Commit when all tasks succeed

### Indirect dispatch example (any agent)

Ask your brains LLM:

> "Generate grunt task definitions to rename `getUser` to `fetchUser` following `local-grunt/TASK_FORMAT.md`."

Then dispatch each task yourself:

```bash
./scripts/dispatch-grunt.sh tasks/GT-001.md
./scripts/dispatch-grunt.sh tasks/GT-002.md
./scripts/dispatch-grunt.sh tasks/GT-003.md
```

---

## Next Steps

- Read [LOCAL_GRUNT_GUIDE.md](../LOCAL_GRUNT_GUIDE.md) for the full human developer guide, including cost optimization and troubleshooting.
- Read [CONSTRAINTS.md](CONSTRAINTS.md) to understand what makes a good grunt task.
- Browse [examples/](examples/) for complete worked decompositions.
- Read the [Brains Integration Patterns](README.md#brains-integration-patterns) section for agent-specific setup (Claude Code, Codex, Cursor).

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
