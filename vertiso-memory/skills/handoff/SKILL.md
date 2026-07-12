---
name: handoff
description: Use when ending a work session, switching tools or devices, or before context is compacted or runs out — gathers past context via the checkpoint skill, composes the handoff's own slots on top, and writes it to Vertiso Memory via the handoff verb (marked claimable) so the next session resumes cleanly.
---

# Handoff

Write a structured session handoff so the work can be picked up cleanly — in this tool or another, now or later.

**Announce:** "Using the handoff skill to checkpoint this session."

## When to use

- The user runs `/handoff`.
- A session is ending, or you are switching tools or devices.
- Context is about to be compacted or run out.

## Procedure

1. **Gather the past context via the checkpoint skill.** Follow the `checkpoint` skill's Procedure steps 1-2 — gather authoritative state from the workstream's own artifacts (checkpoint's gather step has the domain palette: code / writing / product / design / hardware / ops — not git by default) and retrospective-sweep the whole span for the attributed verbatim decisions (who said what). This gathered context FILLS handoff's "What happened" and "Where it stands" slots **verbatim** — carry checkpoint's attributed quotes and detailed snapshot across intact, do not summarize them. It does not replace handoff's body. Do NOT invoke the checkpoint skill itself (that writes a checkpoint memory) — reuse its gather + sweep.
2. **Compose handoff's own body** (below), building the forward slots — Next, Open questions, Verify — ON TOP of that gathered context. Distinguish what was *done* from what was *told* or *believed*; record an approval or decision only if witnessed this session, dated and attributed.
3. **Call the `handoff` verb** — the `handoff` MCP tool, or `vmem handoff` — with the composed body and an agent-supplied `scope` (a git branch for a coding session, a project name, or none). This is handoff's terminal act: it writes the record AND marks it claimable so `handoff_resume` can pick it up.
4. **Report** the new handoff id to the user.

## The six-slot body

Checkpoint's gather (step 1) fills slots 1-3 with the attributed past context; slots 4-6 are handoff's own, built on it.

1. **Working on** — the subject or goal of the session.
2. **What happened** — what was done and decided, with the attributed verbatim that drove it (from checkpoint's sweep).
3. **Where it stands** — the current state in the workstream's terms (from checkpoint's gather).
4. **Next** — the concrete pick-up point.
5. **Open questions / blockers.**
6. **Verify before operating** — the standing advisory: before acting on this handoff, re-check slot 3 against current reality and re-confirm any decision in slot 2.

## Authoring honesty

A handoff is trusted only if it is honest. A claim and a verified fact must not look identical. If you did not witness something this session, say so ("the user said X" / "believed to be Y") rather than asserting it as done.
