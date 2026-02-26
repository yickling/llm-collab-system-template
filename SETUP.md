# Setup Guide

How to adopt the LLM Collaboration System in your project.

## Quick Install

Copy the `docs/memory/` directory into your project root:

```bash
cp -r llm-collab-system-template/docs/memory/ your-project/docs/memory/
```

## Step-by-Step Setup

### 1. Copy the structure

```
your-project/
└── docs/
    └── memory/
        ├── README.md
        ├── PROTOCOL.md
        ├── PROPOSALS.md
        ├── AUDIT_TRAIL.md
        ├── context/
        │   ├── INDEX.md
        │   ├── LATEST.md
        │   ├── MEMORY_TEMPLATE.md
        │   └── IMPLEMENTATION_LOG_TEMPLATE.md
        └── handoffs/
            ├── INDEX.md
            ├── LATEST.md
            ├── SESSION_CLAIM_TEMPLATE.md
            └── SESSION_END_TEMPLATE.md
```

### 2. Customize PROTOCOL.md

- Set the **effective date**.
- Change the default integration branch if you don't use `main`.
- Add project-specific commit types if needed.
- Add project-specific safety constraints (e.g., protected environments, deployment rules).

### 3. Wire into your agent configuration

Reference the protocol in your agent's system instructions or configuration file:

**Claude Code (`CLAUDE.md`)**:
```markdown
## Collaboration Protocol
Before starting any work, read and follow `docs/memory/PROTOCOL.md`.
Review `docs/memory/handoffs/LATEST.md` and `docs/memory/context/LATEST.md` for current state.
```

**Codex (`AGENTS.md`)**:
```markdown
Follow the collaboration protocol in docs/memory/PROTOCOL.md.
Start each session by reviewing the latest handoff and context snapshots.
```

**Cursor (`.cursorrules`)**:
```markdown
This project uses a multi-developer collaboration protocol.
Read docs/memory/PROTOCOL.md before making changes.
Always create a SESSION_CLAIM before starting and SESSION_END before finishing.
```

**Generic (any LLM agent)**:
Include in your system prompt or project instructions:
```
You are collaborating with other developers on this codebase.
Read docs/memory/PROTOCOL.md for the collaboration rules.
Read docs/memory/handoffs/LATEST.md for the most recent session state.
```

### 4. First session

1. Read `PROTOCOL.md` fully.
2. Create your first dated folder: `docs/memory/handoffs/YYYY-MM-DD/`.
3. Copy `SESSION_CLAIM_TEMPLATE.md` into it and fill it out.
4. Do your work.
5. Copy `SESSION_END_TEMPLATE.md` into the same folder and fill it out.
6. Update `AUDIT_TRAIL.md`, `INDEX.md`, and `LATEST.md`.

### 5. Subsequent sessions

Each new developer (human or LLM) starts by:

1. Reading `handoffs/LATEST.md` to find the most recent handoff.
2. Reading that handoff's "State of Thinking" section.
3. Reading `context/LATEST.md` for architectural context.
4. Creating their own `SESSION_CLAIM.md`.

## Directory Conventions

| Path | Purpose | Mutability |
|------|---------|-----------|
| `PROTOCOL.md` | Rules of collaboration | Updated via proposals only |
| `PROPOSALS.md` | Protocol change requests | Append-only |
| `AUDIT_TRAIL.md` | Chronological ledger | Append-only |
| `context/YYYY-MM-DD/` | Architecture snapshots | Immutable per day |
| `handoffs/YYYY-MM-DD/` | Session claim/end notes | Immutable per session |
| `context/INDEX.md` | Snapshot index | Updated when snapshots added |
| `handoffs/INDEX.md` | Handoff index | Updated when handoffs added |
| `*/LATEST.md` | Quick pointer to latest | Updated when new entry is canonical |

## Tips

- **Keep handoffs concise**: The "State of Thinking" section is the highest-value content. Prioritize non-obvious context over exhaustive file lists.
- **Don't skip the claim**: Even for small tasks, a one-line SESSION_CLAIM prevents scope collisions.
- **Templates are starting points**: Omit sections that don't apply, but always include: scope, validation results, state of thinking, and repository state.
- **Use the audit trail**: It's the first place to look when figuring out "what happened and who did it."
