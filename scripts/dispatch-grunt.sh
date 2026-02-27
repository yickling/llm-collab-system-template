#!/bin/bash
# dispatch-grunt.sh
#
# Dispatch a grunt task to a locally-hosted LLM and return the structured result.
# Designed to be called by a brains LLM via shell access, a CI runner, or a human.
#
# Usage:
#   ./scripts/dispatch-grunt.sh <task-file.md>                   # from file
#   echo "<task markdown>" | ./scripts/dispatch-grunt.sh -        # from stdin
#   ./scripts/dispatch-grunt.sh --inline "<task markdown>"        # inline
#
# Environment variables (all optional, with defaults):
#   GRUNT_MODEL        - Model name (default: qwen2.5-coder:7b-instruct)
#   GRUNT_API_URL      - Ollama API endpoint (default: http://localhost:11434)
#   GRUNT_PROVIDER     - API provider: ollama | openai-compat (default: ollama)
#   GRUNT_PROMPT_PATH  - Path to GRUNT_SYSTEM_PROMPT.md (auto-detected)
#   GRUNT_TIMEOUT      - Request timeout in seconds (default: 120)
#
# Supported providers:
#   ollama         - Ollama API (default, localhost:11434)
#   openai-compat  - OpenAI-compatible API (LM Studio, llama.cpp, vLLM, etc.)
#                    Set GRUNT_API_URL to the base URL (e.g., http://localhost:1234/v1)
#
# Exit codes:
#   0 - Task dispatched, result printed to stdout
#   1 - Error (missing dependencies, server unreachable, etc.)
#
# Examples:
#   # Basic usage with a task file
#   ./scripts/dispatch-grunt.sh tasks/GT-2026-02-27-001.md
#
#   # Pipe a task from stdin
#   cat tasks/GT-2026-02-27-001.md | ./scripts/dispatch-grunt.sh -
#
#   # Use a different model
#   GRUNT_MODEL=llama3.1:8b ./scripts/dispatch-grunt.sh task.md
#
#   # Use LM Studio (OpenAI-compatible API)
#   GRUNT_PROVIDER=openai-compat GRUNT_API_URL=http://localhost:1234/v1 \
#     ./scripts/dispatch-grunt.sh task.md
#
#   # Called by a brains LLM (Claude Code) -- inline task
#   ./scripts/dispatch-grunt.sh --inline "$(cat <<'TASK'
#   # GRUNT TASK
#   ## METADATA
#   - task_id: GT-2026-02-27-001
#   ...
#   TASK
#   )"

set -euo pipefail

# --- Configuration ---
GRUNT_MODEL="${GRUNT_MODEL:-qwen2.5-coder:7b-instruct}"
GRUNT_API_URL="${GRUNT_API_URL:-http://localhost:11434}"
GRUNT_PROVIDER="${GRUNT_PROVIDER:-ollama}"
GRUNT_TIMEOUT="${GRUNT_TIMEOUT:-120}"

# --- Locate project root and system prompt ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -n "${GRUNT_PROMPT_PATH:-}" ]; then
    PROMPT_FILE="$GRUNT_PROMPT_PATH"
elif [ -f "$PROJECT_ROOT/local-grunt/GRUNT_SYSTEM_PROMPT.md" ]; then
    PROMPT_FILE="$PROJECT_ROOT/local-grunt/GRUNT_SYSTEM_PROMPT.md"
else
    echo "ERROR: Cannot find GRUNT_SYSTEM_PROMPT.md" >&2
    echo "Set GRUNT_PROMPT_PATH or run from the project root." >&2
    exit 1
fi

# --- Check dependencies ---
if ! command -v curl &> /dev/null; then
    echo "ERROR: curl is required but not installed." >&2
    exit 1
fi
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed." >&2
    echo "Install: brew install jq (Mac) or apt install jq (Linux)" >&2
    exit 1
fi

# --- Read system prompt (between BEGIN/END markers) ---
SYSTEM_PROMPT=$(sed -n '/## BEGIN SYSTEM PROMPT/,/## END SYSTEM PROMPT/p' "$PROMPT_FILE")
if [ -z "$SYSTEM_PROMPT" ]; then
    echo "ERROR: Could not extract system prompt from $PROMPT_FILE" >&2
    echo "Expected markers: '## BEGIN SYSTEM PROMPT' and '## END SYSTEM PROMPT'" >&2
    exit 1
fi

# --- Read task definition ---
if [ "${1:-}" = "--inline" ]; then
    shift
    TASK="$1"
elif [ "${1:-}" = "-" ]; then
    TASK=$(cat)
elif [ -n "${1:-}" ]; then
    if [ ! -f "$1" ]; then
        echo "ERROR: Task file not found: $1" >&2
        exit 1
    fi
    TASK=$(cat "$1")
else
    echo "Usage: dispatch-grunt.sh <task-file.md> | - | --inline <task>" >&2
    exit 1
fi

if [ -z "$TASK" ]; then
    echo "ERROR: Empty task definition." >&2
    exit 1
fi

# --- Check server is reachable ---
check_server() {
    if [ "$GRUNT_PROVIDER" = "ollama" ]; then
        if ! curl -s --max-time 5 "$GRUNT_API_URL/api/tags" > /dev/null 2>&1; then
            echo "ERROR: Ollama server not reachable at $GRUNT_API_URL" >&2
            echo "Start it with: ollama serve" >&2
            exit 1
        fi
    elif [ "$GRUNT_PROVIDER" = "openai-compat" ]; then
        if ! curl -s --max-time 5 "$GRUNT_API_URL/models" > /dev/null 2>&1; then
            echo "ERROR: OpenAI-compatible server not reachable at $GRUNT_API_URL" >&2
            echo "Check that your LM Studio / llama.cpp / vLLM server is running." >&2
            exit 1
        fi
    fi
}

check_server

# --- Dispatch to grunt ---
dispatch_ollama() {
    local response
    response=$(curl -s --max-time "$GRUNT_TIMEOUT" "$GRUNT_API_URL/api/chat" -d "{
        \"model\": \"$GRUNT_MODEL\",
        \"messages\": [
            {\"role\": \"system\", \"content\": $(echo "$SYSTEM_PROMPT" | jq -Rs .)},
            {\"role\": \"user\", \"content\": $(echo "$TASK" | jq -Rs .)}
        ],
        \"stream\": false,
        \"options\": {
            \"temperature\": 0.0,
            \"num_predict\": 2048
        }
    }" 2>&1)

    if [ $? -ne 0 ]; then
        echo "ERROR: curl request failed." >&2
        echo "$response" >&2
        exit 1
    fi

    # Check for API error
    local error
    error=$(echo "$response" | jq -r '.error // empty' 2>/dev/null)
    if [ -n "$error" ]; then
        echo "ERROR: Ollama API error: $error" >&2
        exit 1
    fi

    echo "$response" | jq -r '.message.content'
}

dispatch_openai_compat() {
    local response
    response=$(curl -s --max-time "$GRUNT_TIMEOUT" "$GRUNT_API_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$GRUNT_MODEL\",
            \"messages\": [
                {\"role\": \"system\", \"content\": $(echo "$SYSTEM_PROMPT" | jq -Rs .)},
                {\"role\": \"user\", \"content\": $(echo "$TASK" | jq -Rs .)}
            ],
            \"temperature\": 0.0,
            \"max_tokens\": 2048
        }" 2>&1)

    if [ $? -ne 0 ]; then
        echo "ERROR: curl request failed." >&2
        echo "$response" >&2
        exit 1
    fi

    # Check for API error
    local error
    error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
    if [ -n "$error" ]; then
        echo "ERROR: API error: $error" >&2
        exit 1
    fi

    echo "$response" | jq -r '.choices[0].message.content'
}

# --- Main ---
case "$GRUNT_PROVIDER" in
    ollama)
        dispatch_ollama
        ;;
    openai-compat)
        dispatch_openai_compat
        ;;
    *)
        echo "ERROR: Unknown provider '$GRUNT_PROVIDER'. Use 'ollama' or 'openai-compat'." >&2
        exit 1
        ;;
esac
