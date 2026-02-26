# Adapting for Simultaneous Multi-Developer Work

The base protocol assumes **sequential** sessions: one developer works at a time, hands off, and the next picks up. This document describes the changes needed to support **multiple developers working simultaneously** on the same codebase.

---

## Problem Statement

The sequential model breaks down when:

- Two LLM agents (or a human + LLM) edit at the same time
- Developers are in different time zones and sessions overlap
- A CI pipeline or automated agent works in the background while someone else codes

The core risks are: **conflicting edits**, **stale handoff state**, and **lost context**.

---

## Required Changes to the Protocol

### 1. Replace Soft Locks with Branch-Based Isolation

**Current (sequential)**: Soft lock model -- first to claim a file owns it.

**Change**: Each concurrent developer works on a **dedicated branch**, not directly on `main`.

```
Branch naming: <agent>/<scope>    e.g. claude/add-auth, codex/fix-api
```

**Rules**:
- No two developers commit to the same branch simultaneously.
- `main` is protected -- changes land via pull request or merge only.
- Each developer's `SESSION_CLAIM.md` records their branch name.
- Merges to `main` require validation gate to pass.

**Rationale**: Branches provide hard isolation. Soft locks fail silently when two agents start at the same time.

### 2. Add a Lockfile for Active Sessions

Create `docs/memory/ACTIVE_SESSIONS.md` -- a lightweight registry of who is currently working.

```markdown
# Active Sessions

| Developer | Branch | Scope | Started (UTC) | Status |
|-----------|--------|-------|---------------|--------|
| Claude | claude/add-auth | Auth module | 2026-02-26T14:00Z | ACTIVE |
| Codex | codex/fix-api | API error handling | 2026-02-26T14:30Z | ACTIVE |
```

**Rules**:
- Register before starting (add row with ACTIVE status).
- Deregister when done (change status to COMPLETED or remove row).
- If you see another developer's claimed scope overlaps yours, **stop and coordinate** before proceeding.
- Stale entries (>24h with no commit) can be marked STALE by any developer and investigated.

**Rationale**: Provides at-a-glance visibility into who is working on what, which soft locks alone cannot do when sessions overlap.

### 3. Scope Partitioning with Explicit File Ownership

**Current**: Implicit "first to claim owns it."

**Change**: Add a `Files Owned` column to the active sessions registry, listing specific files or directories.

```markdown
| Developer | Branch | Scope | Files Owned | Started (UTC) |
|-----------|--------|-------|-------------|---------------|
| Claude | claude/add-auth | Auth | src/auth/*, tests/auth/* | 2026-02-26T14:00Z |
| Codex | codex/fix-api | API | src/api/errors.py | 2026-02-26T14:30Z |
```

**Rules**:
- File ownership is **exclusive** -- no two developers may list the same file.
- Shared files (e.g., `schema.sql`, `package.json`) require a **coordination comment** in the session claim explaining what you'll change and why, so the other developer can avoid conflicting edits.
- If you need a file someone else owns, request it via a handoff note or direct message.

### 4. Introduce Merge Coordination

When multiple branches need to merge into `main`:

**Option A: Sequential Merge Queue**

Developers merge one at a time in order of completion. Each merge must:
1. Rebase onto latest `main`
2. Pass validation gate
3. Update `AUDIT_TRAIL.md` and handoff docs

**Option B: Merge Coordinator Role**

Designate one developer (human preferred) as the merge coordinator who:
1. Reviews branch diffs for conflicts
2. Decides merge order
3. Resolves conflicts or delegates resolution
4. Updates `AUDIT_TRAIL.md` with the merge entry

**Recommendation**: Start with Option A (simpler). Move to Option B when the team exceeds 3 concurrent developers.

### 5. Split Handoff Notes per Developer

**Current**: One `SESSION_END.md` per day.

**Change**: Use agent-scoped filenames within the same date folder:

```
docs/memory/handoffs/YYYY-MM-DD/
├── SESSION_CLAIM_CLAUDE.md
├── SESSION_CLAIM_CODEX.md
├── SESSION_END_CLAUDE.md
├── SESSION_END_CODEX.md
```

**Rules**:
- Each developer writes only their own files.
- The `INDEX.md` and `LATEST.md` list all files, not just one.
- If a developer has multiple sessions in one day, append a sequence number: `SESSION_END_CLAUDE_2.md`.

### 6. Conflict Detection Hooks

Add a **pre-merge check** (CI or script) that:

1. Parses `ACTIVE_SESSIONS.md` for overlapping file ownership.
2. Compares the branch's changed files against other active branches.
3. Flags potential conflicts before merge.

Example script concept:

```bash
#!/bin/bash
# conflict-check.sh: Compare this branch's changed files against active sessions
CHANGED_FILES=$(git diff --name-only main...HEAD)
# Parse ACTIVE_SESSIONS.md for other developers' file ownership
# Flag overlaps and exit non-zero if conflicts detected
```

This can be wired into CI or run manually before merging.

### 7. Real-Time Communication Channel

For truly simultaneous work, documentation alone may be too slow. Add:

- A **shared status file** (`ACTIVE_SESSIONS.md` above) for async coordination.
- A **communication convention**: If agents can't message each other directly, they leave coordination notes in `docs/memory/handoffs/YYYY-MM-DD/COORDINATION.md` -- an append-only file for same-day messages.

```markdown
# Coordination Notes - YYYY-MM-DD

## 14:30 UTC - Claude
I need to modify `schema.sql` to add the `roles` table. @Codex, are you touching this file?

## 14:45 UTC - Codex
No, go ahead. I'm only in `src/api/errors.py`.
```

This is a low-tech fallback. In practice, teams should prefer a real communication channel (Slack, Discord, etc.) and reference it from the protocol.

---

## Summary of Changes

| Aspect | Sequential (Base) | Simultaneous (New) |
|--------|------------------|--------------------|
| **Isolation** | Soft file locks | Branch-per-developer |
| **Visibility** | LATEST.md pointers | ACTIVE_SESSIONS.md registry |
| **File ownership** | Implicit first-claim | Explicit file list in registry |
| **Merging** | Direct to main | PR-based merge queue |
| **Handoff files** | One per day | One per developer per day |
| **Conflict detection** | Manual (stop + escalate) | Automated pre-merge checks |
| **Communication** | Handoff notes only | COORDINATION.md + external channels |
| **Branch naming** | N/A (all on main) | `<agent>/<scope>` convention |

---

## Migration Path

To move from sequential to simultaneous:

1. **Protect `main`**: Require PRs or merge-only access.
2. **Create `ACTIVE_SESSIONS.md`**: Add it to `docs/memory/`.
3. **Update `PROTOCOL.md`**: Add sections 4a (branch isolation), 4b (file ownership registry), and 10a (merge coordination).
4. **Add branch naming convention**: Document in protocol.
5. **Set up conflict-check script**: Wire into CI or document as a manual step.
6. **Update agent configurations**: Instruct agents to check `ACTIVE_SESSIONS.md` at session start and register themselves.
7. **Start using agent-scoped handoff filenames**: `SESSION_END_<AGENT>.md`.

These changes are **additive** -- they don't break the sequential workflow. A single developer can ignore `ACTIVE_SESSIONS.md` and work exactly as before. The new mechanics only activate when multiple developers are active.
