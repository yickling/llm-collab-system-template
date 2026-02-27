# Local Grunt Guide

How to use small, locally-hosted LLMs to handle mechanical coding tasks at near-zero cost.

## Why Use Local Grunts?

API-hosted LLMs (Claude, GPT-4) are powerful but expensive. Most coding work falls into two categories:

| Category | Example | Needs Reasoning? | Cost |
|----------|---------|------------------|------|
| **Thinking** | "Design an auth system" | Yes | High (brains LLM) |
| **Doing** | "Replace `getUser` with `fetchUser` in line 42" | No | Low (grunt LLM) |

The grunt protocol lets you offload the "doing" category to free, locally-hosted models. A strong LLM does the thinking once, then generates precise task definitions that a small model executes mechanically.

**Cost comparison (approximate, per 1000 tasks)**:

| Approach | Cost |
|----------|------|
| All tasks via Claude API | ~$15-50 |
| All tasks via GPT-4 API | ~$20-60 |
| Brains (1 API call to plan) + Grunts (1000 local calls) | ~$0.03-0.10 |

The brains makes one API call to decompose the work. The grunts run locally for free.

## How It Works

```
You (or your CI pipeline) identify a change needed
        │
        ▼
Brains LLM (API-hosted, strong reasoning)
  1. Reads the relevant source files
  2. Understands what needs to change
  3. Decomposes the change into atomic grunt tasks
  4. Generates task definitions in structured markdown
        │
        ▼
Task Runner (script or manual dispatch)
  1. Reads task definitions
  2. Resolves dependency ordering (depends_on fields)
  3. Feeds each task to a grunt LLM one at a time
  4. Collects results
        │
        ▼
Grunt LLM (locally-hosted, small model)
  1. Receives system prompt + one task definition
  2. Checks preconditions
  3. Executes the operation mechanically
  4. Runs validation checks
  5. Reports DONE / BLOCKED / FAILED
        │
        ▼
Results flow back to Brains (or to you)
  - DONE: change was applied successfully
  - BLOCKED: task definition was wrong (regenerate)
  - FAILED: operation had unexpected result (investigate)
```

## What You Need

### Hardware

Grunt LLMs are small. Minimum requirements:

| Model Size | RAM Required | GPU (optional) | Speed |
|------------|-------------|----------------|-------|
| 7B params | 8 GB | Any 6GB+ VRAM GPU | ~20 tokens/sec CPU, ~80 GPU |
| 13B params | 16 GB | Any 10GB+ VRAM GPU | ~10 tokens/sec CPU, ~50 GPU |
| 20B params | 24 GB | Any 16GB+ VRAM GPU | ~6 tokens/sec CPU, ~35 GPU |

A 7B model on a modern laptop is sufficient for most grunt tasks.

### Software

You need a local LLM inference server. Popular options:

| Tool | Platform | Setup Complexity |
|------|----------|-----------------|
| [Ollama](https://ollama.ai) | Mac, Linux, Windows | Easiest -- one command install |
| [LM Studio](https://lmstudio.ai) | Mac, Linux, Windows | GUI-based, beginner friendly |
| [llama.cpp](https://github.com/ggerganov/llama.cpp) | All platforms | CLI, most configurable |
| [vLLM](https://github.com/vllm-project/vllm) | Linux (GPU) | Best throughput for GPU servers |

### Recommended Models

For grunt work, you want models that follow instructions precisely rather than being "creative." Good choices:

| Model | Size | Why |
|-------|------|-----|
| Qwen 2.5 Coder 7B Instruct | 7B | Purpose-built for code, strong instruction following |
| Llama 3.1 8B Instruct | 8B | Good general instruction following |
| DeepSeek Coder V2 Lite | 16B | Excellent at code tasks, slightly larger |
| Mistral 7B Instruct | 7B | Reliable instruction following |

Avoid base (non-instruct) models -- they will not follow the structured task format.

## Setup Walkthrough

### Option A: Ollama (Recommended for Getting Started)

```bash
# 1. Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# 2. Pull a model
ollama pull qwen2.5-coder:7b-instruct

# 3. Test it works
ollama run qwen2.5-coder:7b-instruct "Say hello"

# 4. Start the API server (runs on localhost:11434 by default)
ollama serve
```

### Option B: LM Studio

1. Download from [lmstudio.ai](https://lmstudio.ai)
2. Search for and download `Qwen 2.5 Coder 7B Instruct` (GGUF format)
3. Go to the "Local Server" tab
4. Load the model and click "Start Server"
5. The API will be available at `localhost:1234`

### Option C: llama.cpp Server

```bash
# 1. Build llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp && make

# 2. Download a GGUF model (e.g., from HuggingFace)
# Place it in models/

# 3. Start the server
./llama-server -m models/qwen2.5-coder-7b-instruct.Q4_K_M.gguf \
  --host 0.0.0.0 --port 8080 -c 4096
```

## Dispatching Tasks

### Manual Dispatch (Simple)

For occasional use, you can dispatch tasks manually:

1. Have your brains LLM generate task definitions (paste the `TASK_FORMAT.md` and relevant `task-types/` docs into its context).
2. Copy the system prompt from `GRUNT_SYSTEM_PROMPT.md`.
3. Send the system prompt + task definition to your local LLM.
4. Read the grunt's structured result.
5. Apply the change if DONE, or investigate if BLOCKED/FAILED.

### Script-Based Dispatch (Recommended)

Write a simple script that:

1. Reads task definitions from a directory or stdin
2. Resolves `depends_on` ordering
3. Sends each task to the local LLM API
4. Collects and stores results
5. Reports summary to the brains or to you

Example using Ollama's API:

```bash
#!/bin/bash
# dispatch-grunt-task.sh
# Usage: ./dispatch-grunt-task.sh task-definition.md

SYSTEM_PROMPT=$(cat local-grunt/GRUNT_SYSTEM_PROMPT.md | sed -n '/## BEGIN SYSTEM PROMPT/,/## END SYSTEM PROMPT/p')
TASK=$(cat "$1")

curl -s http://localhost:11434/api/chat -d "{
  \"model\": \"qwen2.5-coder:7b-instruct\",
  \"messages\": [
    {\"role\": \"system\", \"content\": $(echo "$SYSTEM_PROMPT" | jq -Rs .)},
    {\"role\": \"user\", \"content\": $(echo "$TASK" | jq -Rs .)}
  ],
  \"stream\": false
}" | jq -r '.message.content'
```

### Brains LLM Integration

If your brains LLM has tool/function calling or shell access, it can dispatch grunt tasks directly:

1. Brains generates the task definition
2. Brains calls the local LLM API with the system prompt + task
3. Brains reads the structured result
4. Brains decides next steps based on the result

See [local-grunt/README.md](local-grunt/README.md) for detailed brains integration patterns.

## Cost Optimization Strategies

### 1. Batch Similar Changes

Instead of asking the brains to handle each file individually, ask it to generate a batch of grunt tasks for all files at once. One brains API call can produce 20 grunt tasks.

### 2. Use SEARCH_REPORT First

Let grunts do the file scanning (free), then feed the results to the brains for task generation. This saves brains tokens on reading file contents.

### 3. Cache the System Prompt

Most local LLM servers support prompt caching. The grunt system prompt is the same every time, so it only needs to be processed once.

### 4. Parallelize Independent Tasks

Tasks without `depends_on` relationships can run on multiple grunt instances simultaneously. If you have a GPU, run multiple inference threads.

### 5. Reserve the Brains for Decisions Only

The brains should only be called for:
- Initial task decomposition
- Handling BLOCKED/FAILED results (deciding what to regenerate)
- Final review of all changes before committing

Everything else is grunt work.

## What Tasks Work Best as Grunt Work?

### High confidence (use grunts freely)

- Renaming variables/functions across files (SEARCH_REPORT + EDIT)
- Adding import statements (INSERT)
- Creating boilerplate files from exact specifications (CREATE)
- Updating version numbers (EDIT)
- Adding entries to logs, audit trails, changelogs (APPEND)
- Running tests and reporting results (VALIDATE)
- Deleting deprecated files (DELETE)

### Medium confidence (verify results)

- Multi-line code edits where the surrounding context is stable (EDIT)
- Inserting new functions into existing files (INSERT with a long anchor)
- Bulk string replacements across many files (EDIT with `occurrence: ALL`)

### Low confidence (keep for brains)

- Writing new logic, even simple logic
- Modifying conditional statements
- Anything where the correct output depends on understanding what the code does
- Changes near recently-modified code (high risk of stale `find_exact` strings)

## Troubleshooting

### Grunt returns BLOCKED on most tasks

The task definitions are likely stale -- the source files have changed since the brains generated them. Re-read the files and regenerate tasks.

### Grunt adds extra content to files

The system prompt may not be loading correctly, or the model is too small to follow the prohibitions. Try a slightly larger model (13B) or verify the system prompt is being sent as a system message, not a user message.

### Grunt output doesn't match the expected format

Some models struggle with the structured output format. Try a different model, or add a few-shot example to the system prompt showing a correct result.

### Tasks take too long

Reduce the `content` field size. Large file contents (100+ lines) slow down small models significantly. Split into smaller tasks.
