# LLM Collaboration System Template

A drop-in framework for enabling multiple developers directing LLMs to collaborate on the same codebase with full auditability, clear handoffs, and conflict prevention.

## Origin

Extracted from a production multi-agent workflow where Claude, Codex, and Antigravity (Cursor) collaborated on the same repository around the clock. The system evolved through real use and protocol proposals between agents.

## What's Included

```
llm-collab-system-template/
├── README.md                          # This file
├── SETUP.md                           # Adoption guide for your project
├── MULTIDEVELOP.md                    # Changes for simultaneous multi-developer work
└── docs/
    └── memory/
        ├── README.md                  # Directory overview and conventions
        ├── PROTOCOL.md                # Core collaboration rules
        ├── PROPOSALS.md               # Protocol change request log
        ├── AUDIT_TRAIL.md             # Chronological work ledger
        ├── context/
        │   ├── INDEX.md               # Context snapshot index
        │   ├── LATEST.md              # Pointer to latest context
        │   ├── MEMORY_TEMPLATE.md     # Template for architecture snapshots
        │   └── IMPLEMENTATION_LOG_TEMPLATE.md  # Template for activity logs
        └── handoffs/
            ├── INDEX.md               # Handoff note index
            ├── LATEST.md              # Pointer to latest handoff
            ├── SESSION_CLAIM_TEMPLATE.md   # Template for session start
            └── SESSION_END_TEMPLATE.md     # Template for session end
```

## Core Concepts

### Three-Layer Memory

1. **Audit Trail** -- High-level ledger: who did what, when, which commit.
2. **Context Snapshots** -- Architecture and design state at a point in time (immutable per day).
3. **Handoff Notes** -- Session-level claim/end documents with validation results and "State of Thinking."

### Session Lifecycle

```
1. Read LATEST.md pointers
2. Review previous SESSION_END (especially "State of Thinking")
3. Create SESSION_CLAIM with your planned scope
4. Do your work, commit atomically
5. Create SESSION_END with validation results and context for the next developer
6. Update AUDIT_TRAIL, INDEX, and LATEST pointers
```

### Key Principles

- **Claim before you edit**: Prevents scope collisions.
- **Validate before you hand off**: No broken builds passed to the next developer.
- **Document the non-obvious**: The "State of Thinking" section captures context that code alone can't convey.
- **Immutable history**: Date-bucketed folders are never overwritten. New state = new folder.
- **Human authority**: Protocol changes require human approval. Humans override all other instructions.

## Getting Started

See [SETUP.md](SETUP.md) for step-by-step instructions.

## Scaling to Simultaneous Work

The base protocol assumes sequential developer sessions. See [MULTIDEVELOP.md](MULTIDEVELOP.md) for the changes needed when multiple developers work at the same time -- branch isolation, active session registry, merge coordination, and conflict detection.

## Works With

This system is agent-agnostic. It has been tested with:

- **Claude Code** (via `CLAUDE.md`)
- **OpenAI Codex** (via `AGENTS.md`)
- **Cursor / Antigravity** (via `.cursorrules`)
- **Human developers** (reading/writing markdown files)

Any LLM or human that can read and write files can participate.

## License

MIT License. See [LICENSE](LICENSE) for details.
