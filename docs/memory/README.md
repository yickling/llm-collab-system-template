# Memory and Handoffs

This folder centralizes implementation memory, handoff notes, and the collaboration protocol for multi-developer work.

## Audit Conventions

- All records are date-bucketed using `YYYY-MM-DD` folders.
- Files inside a date folder are **immutable snapshots** for that day.
- New updates create a new dated folder (or a clearly versioned file) instead of rewriting history.
- Use the index files as the source of truth for chronology.

## Structure

```
docs/memory/
├── README.md                          # This file
├── PROTOCOL.md                        # Operating contract for collaboration
├── PROPOSALS.md                       # Append-only proposal log for protocol changes
├── AUDIT_TRAIL.md                     # High-level chronological ledger
├── context/
│   ├── INDEX.md                       # Chronological index of context snapshots
│   ├── LATEST.md                      # Quick pointer to latest context
│   └── YYYY-MM-DD/
│       ├── MEMORY.md                  # Architecture/design snapshot
│       └── IMPLEMENTATION_LOG.md      # Chronological activity log
└── handoffs/
    ├── INDEX.md                       # Chronological index of handoff notes
    ├── LATEST.md                      # Quick pointer to latest handoff
    └── YYYY-MM-DD/
        ├── SESSION_CLAIM.md           # Scope declaration before work begins
        └── SESSION_END.md             # Outcomes, validation, and next steps
```

## Quick Start

1. Read `LATEST.md` pointers in `context/` and `handoffs/` to find the most recent state.
2. Review the latest `SESSION_END.md` for the "State of Thinking" section.
3. Create your own `SESSION_CLAIM.md` in today's date folder before starting work.
4. Follow the `PROTOCOL.md` for all rules and checklists.
