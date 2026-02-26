# LLM Collaboration Protocol

Effective date: YYYY-MM-DD
Applies to: All LLM agents and human developers working in this repository.

## 1. Purpose

This protocol defines operating terms so multiple developers (human or LLM) can work on the same codebase without corrupting state, duplicating effort, or losing auditability. It supports both **sequential** (one active session at a time) and **simultaneous** (multiple developers at once) workflows via branch-based isolation and an active session registry.

## 2. Priority Order

When instructions conflict, apply this order:

1. Human developer direct instruction (highest)
2. Repository policy files (`AGENTS.md`, `CLAUDE.md`, contributor docs)
3. This protocol
4. Agent/tool defaults (lowest)

## 3. Role Boundaries

1. Each developer must **claim a task scope** before making edits.
2. Claimed scope must be recorded in a dated handoff note **before** major edits begin.
3. A developer must not edit files outside claimed scope unless:
   - required for compile/test integration, **and**
   - explicitly documented in handoff notes.

## 4. File Ownership and Concurrency

### 4a. Branch-Based Isolation (Simultaneous Work)

When multiple developers work at the same time, each developer works on a **dedicated branch**, not directly on `main`.

**Branch naming convention**: `<agent>/<scope>` (e.g., `claude/add-auth`, `codex/fix-api`)

**Rules**:
- No two developers commit to the same branch simultaneously.
- `main` is protected -- changes land via pull request or merge only.
- Each developer's `SESSION_CLAIM.md` records their branch name.
- Merges to `main` require the validation gate (Section 7) to pass.

### 4b. File Ownership Registry

When working simultaneously, developers must register in `docs/memory/ACTIVE_SESSIONS.md` with explicit file ownership:

| Developer | Branch | Scope | Files Owned | Started (UTC) | Status |
|-----------|--------|-------|-------------|---------------|--------|

**Rules**:
1. **Register before starting**: Add a row with ACTIVE status before making edits.
2. **Deregister when done**: Change status to COMPLETED or remove your row.
3. **File ownership is exclusive** -- no two developers may list the same file.
4. **Shared files** (e.g., `schema.sql`, `package.json`) require a coordination comment in the session claim explaining what you'll change and why.
5. If you need a file someone else owns, request it via a handoff note or coordination message.
6. **Stale entries**: Sessions with no commit activity for >24h may be marked STALE by any developer.

### 4c. Sequential Fallback

For sequential workflows (one developer at a time), the simpler soft-lock model still applies:

1. First developer to claim a file owns it for the active task window.
2. No dual editing of the same file in parallel.
3. If overlap is required, perform a sequential handoff:
   - Developer A commits/publishes state
   - Developer A records status + known risks
   - Developer B takes ownership after acknowledgement

## 5. Branch and Commit Contract

1. Default integration branch is `main` unless the team directs otherwise.
2. **Branch naming**: Use `<agent>/<scope>` for feature/task branches (e.g., `claude/add-auth`, `codex/fix-api`).
3. **`main` is protected**: Changes land via pull request or merge only when multiple developers are active.
4. Commits must be **atomic** and scoped to one concern.
5. Commit messages follow `<type>: <summary>` format.
   - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`
   - Example: `feat: add user authentication endpoint`
6. Do not include unrelated workspace changes in a commit.
7. Never amend or rewrite another developer's commit history unless explicitly requested by a human.

## 6. Documentation and Audit Requirements

For each completed task, the acting developer must update **all** of:

1. **Context snapshot** under `docs/memory/context/YYYY-MM-DD/` (if behavior/architecture changed)
2. **Handoff note** under `docs/memory/handoffs/YYYY-MM-DD/` (what changed, what remains)
3. **Audit trail** in `docs/memory/AUDIT_TRAIL.md` with date, actor, action, git reference
4. **LATEST.md pointers** if the new snapshot is now canonical

### Minimum Handoff Content

1. Files changed
2. Commands run
3. Test results and failures
4. Open risks/blockers
5. Exact commit hash(es)

### Timestamps

All timestamps in audit trail and handoff notes should use **UTC** to avoid timezone confusion.

## 7. Validation Gate

Before handoff or push, the developer must run the strongest available validation for the changed scope:

1. Targeted tests (unit, integration)
2. Syntax/compile checks if tests are unavailable
3. Smoke run for critical runtime paths when feasible

If validation **cannot** run, the handoff must state:

1. What could not run
2. Why
3. Exact command to run later

## 8. Safety Constraints

1. No destructive commands (`reset --hard`, force checkout, broad deletes) without explicit human request.
2. Do not revert files touched by another developer unless explicitly requested.
3. Preserve uncommitted unrelated changes.
4. Network/escalated commands (deploys, external API calls) require explicit approval.

## 9. Conflict Resolution

If two developers touched overlapping scope and behavior diverges:

1. **Stop** further edits immediately.
2. **Record** the divergence in a handoff note.
3. **Produce** a minimal reconciliation patch.
4. **Escalate** the decision to a human with options and tradeoffs.

## 10. Handoff SLA

At end of each work session, the developer must leave the repository in **one** of these states:

1. Clean commit + pushed + documented
2. Local commit pending push + documented
3. Uncommitted WIP + explicitly documented as WIP with the next command to continue

**No silent partial state.**

## 10a. Merge Coordination (Simultaneous Work)

When multiple branches need to merge into `main`:

**Sequential Merge Queue** (default for ≤3 concurrent developers):

1. Developers merge one at a time in order of completion.
2. Each merge must:
   - Rebase onto latest `main`
   - Pass the validation gate (Section 7)
   - Update `AUDIT_TRAIL.md` and handoff docs

**Merge Coordinator Role** (for >3 concurrent developers):

1. Designate one developer (human preferred) as the merge coordinator.
2. The coordinator:
   - Reviews branch diffs for conflicts
   - Decides merge order
   - Resolves conflicts or delegates resolution
   - Updates `AUDIT_TRAIL.md` with the merge entry

**Pre-merge conflict check**: Before merging, run `scripts/conflict-check.sh` (or equivalent CI step) to detect overlapping file changes across active branches.

## 10b. Real-Time Coordination (Simultaneous Work)

For same-day coordination between developers who cannot message each other directly:

1. Use `docs/memory/handoffs/YYYY-MM-DD/COORDINATION.md` as an **append-only** message log.
2. Each entry includes UTC timestamp and developer name.
3. For urgent coordination, prefer an external channel (Slack, Discord, etc.) and reference it in the protocol configuration.

## 11. Session Start Checklist (Mandatory)

Before starting edits, verify:

- [ ] Current branch
- [ ] Current git status (clean/dirty)
- [ ] Checked `ACTIVE_SESSIONS.md` for scope conflicts (simultaneous work)
- [ ] Registered yourself in `ACTIVE_SESSIONS.md` with branch, scope, and files owned (simultaneous work)
- [ ] Claimed scope recorded in a new `SESSION_CLAIM_<AGENT>.md`
- [ ] Reviewed latest memory docs (`LATEST.md` pointers)
- [ ] Reviewed latest handoff note (especially "State of Thinking")

## 12. Session End Checklist (Mandatory)

Before stopping, verify:

- [ ] Changes scoped correctly (no out-of-scope edits)
- [ ] Validation performed or gap documented
- [ ] Handoff note updated (`SESSION_END_<AGENT>.md`)
- [ ] Audit trail updated
- [ ] Commit hash and status recorded
- [ ] `LATEST.md` pointers updated if applicable
- [ ] Connectivity/environment snapshot documented (if external services used)
- [ ] `ACTIVE_SESSIONS.md` updated (mark COMPLETED or remove row) (simultaneous work)

## 13. Attribution

- Use a **single, specific name** per session in the `Actor` field (e.g., `Claude`, `Codex`, `Cursor`, `Alice`).
- Avoid combined tags like `Codex/Claude` to maintain clear session boundaries.
- Human developers should use their name or handle consistently.

## 14. Change Control for This Protocol

1. Any developer may propose modifications via `docs/memory/PROPOSALS.md`.
2. Modifications are valid only after human approval.
3. Protocol revisions should append a short changelog at the bottom of this file.

---

## Protocol Changelog

- YYYY-MM-DD: Initial version created from llm-collab-system-template.
- 2026-02-26: Added simultaneous multi-developer support: branch isolation (4a), file ownership registry (4b), merge coordination (10a), real-time coordination (10b), agent-scoped handoff filenames, and updated checklists.
