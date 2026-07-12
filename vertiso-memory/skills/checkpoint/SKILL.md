---
name: checkpoint
description: Save work-in-progress to Vertiso Memory without ending the session — a richer, resume-critical snapshot than a handoff, captured mid-stream, that preserves the session's decisions and their whys verbatim across every topic it touched. Two modes: routine (periodic "it's been a while since I saved" — sweeps the whole span) and salient (immediate "don't want to forget this — this matters"). The shared capture engine that handoff and wrap-up delegate their state-assembly to. Use when the user or agent says checkpoint / save progress / capture this / don't forget this, or on a cadence nudge.
---

# Checkpoint

Persist the current state of ongoing work — richly enough that a cold context (a compaction, a crash, a next-day return) resumes without re-deriving the reasoning, AND without losing the decisions and whys that got the work here. Checkpoint is the capture *engine*; handoff and wrap-up are terminal wrappers over it.

**Announce:** "Using the checkpoint skill to save progress."

## When to use

Two modes, two triggers:

- **Salient** (event-driven) — the moment something worth not-forgetting happens: a decision made, an ah-ha, a why settled, a constraint stated, a dead-end proven. Triggered by "capture this" / "don't forget this," from the user OR the agent noticing it in the moment. Writes immediately, small and focused.
- **Routine** (cadence-driven) — "it's been a while since we saved." Sweeps the whole span since the last durable capture, preserves its decisions verbatim, and snapshots current state. Three ways it fires, in order of reliability:
  1. **User** — `/checkpoint`. The manual floor, works everywhere.
  2. **Client hook** — a turn/tool counter nudging every N (where the client has hooks, e.g. Claude Code's `Stop`). Deterministic; the reliable upgrade.
  3. **Agent self-check** — the portable fallback for clients with no hooks. You can't track wall-clock between turns, but you CAN notice when several decisions have accumulated or the thread has moved substantially since the last checkpoint. When it has, proactively offer a routine checkpoint. Soft and judgment-based, but it's the only cadence a hook-less client (Antigravity, possibly Cursor) has — so do it. A server (vmem) cannot drive this: it sees vmem calls, not your turns.

Not this skill: **handoff** (you are leaving — adds a claimable resume protocol), **wrap-up** (work is done — archives intents and closes), **goodbye** (session lifecycle). All three call this skill's assembly, then add their terminal act.

## Selection — two capture paths, both valid

The goal is every decision, why, constraint, reversal, and ah-ha preserved — not the whole transcript. Two paths get there:

- **Immediate (salient mode).** When a moment is flagged — by the user or the agent, in the moment — capture it verbatim right then. Zero reconstruction, zero bias, nothing lost to a later compaction. Front-load capture this way whenever possible.
- **Retrospective sweep (routine mode).** At a routine checkpoint, sweep the ENTIRE span since the last durable capture — the whole session for the first checkpoint — and pull, verbatim, every turn that carries a decision, a constraint, a correction/reversal, or an explicit *why*. **Across every topic the span touched, not just the recent ones.** A long multi-topic session gets each topic's decisions captured; recency must not crowd out the earlier topics. Narrowing the sweep to the current workstream and dropping the session's earlier topics is exactly how "everything I said" gets lost — do not do it.

The hindsight-bias guard is NOT "don't look back." It is *what* you look for:
- Capture turns with an objective decision-marker — a choice made, a constraint stated, a correction, a reversal, an explicit reason — plus agent turns that establish context or carry an insight/diagnosis worth keeping. Not turns that merely felt eventful.
- The user's verbatim words are highest-priority (authored intent, easy to distort in summary), but agent turns count when they carry signal. Attribute every capture to who spoke it.
- When unsure whether a turn matters, it probably doesn't — skip it.
- Signal turns are a small fraction of the conversation; capture those, drop the rest. Never paste the whole transcript.

**Skip what is already durably captured.** If a prior checkpoint, handoff, or wrap-up this session already preserved a topic's decisions verbatim, do not re-capture them — link that memory instead. But a *summary* elsewhere does not count as verbatim preservation: if the exact words matter and only a paraphrase exists, capture them.

## Verbatim discipline

Verbatim is the point — a summary of *why* a decision was made loses the decision. But verbatim is not "dump the transcript." Skim for the turns that carry signal; capture those, slightly more generously than a handoff would, and skip the rest.

- **Quote from the transcript, not from working memory.** If the client exposes a session transcript, READ IT and pull the exact words from it. Claude Code persists one as a `.jsonl` under the session directory (its path is surfaced in-session, e.g. a compaction notice); other harnesses may expose their own — check yours. Reconstructing quotes from working context silently paraphrases: the words drift, the attribution blurs, and "verbatim" becomes a claim you can't back. That defeats the whole skill. Only fall back to reconstruction when no transcript is reachable — and when you do, mark those quotes as reconstructed (a `~` prefix or a trailing "(reconstructed)") so a reader knows they are approximate, not exact. A quote presented as verbatim must actually be verbatim.
- **Attribute every quote to who spoke it.** Vertiso Memory models authorship well, but only at the memory level (the checkpoint's own `source`), which can't say who said each *quoted line* inside it. So attribute inline — the human by name, the agent by its name/source:
  > "we do flip both ways when the honest thing to do is to do so" — John
  > "the alias schemes create an edge but never chip — they'll drift" — Claude Code
- **Capture the user's exact words** for decisions, constraints, preferences, and reversals — highest priority, and never cleaned up.
- **Capture agent turns verbatim too when they carry context worth keeping** — a diagnosis, an insight, the rationale behind a call, a caveat you'll need later. Not every agent turn (they're bulky); skim for the ones that establish context or are themselves the thing to remember. When it's just routine reasoning, summarize or skip.
- **Layer it.** The body is structured resume-state (so a receiving agent resumes with minimum follow-up work), with the attributed verbatim excerpts cited *inside* the relevant slot as evidence — not a raw transcript slab appended at the end.

## Procedure

1. **Gather state from the workstream's OWN artifacts** — whatever records the work — not the transcript's narrative, and NOT git by default. Git commits, PRs, and SHAs are *software's* artifacts; most work is not software. Match the domain:
   - **Software / eng** — `git status` / `git diff` (INCLUDING uncommitted), `git log` since the boundary, `gh pr` state, gate/test results.
   - **Writing / docs** — the draft file + version + sections done vs outstanding.
   - **Product / PM** — the PRD or spec, roadmap, ticket/issue states, the decision log.
   - **Design / art** — file revisions, the board/canvas, what's approved vs in-progress, exports sent.
   - **Hardware / mechanical** — CAD revisions, the BOM, test-rig results, prototype status.
   - **Entrepreneur / ops** — the deck, the model, deal/contract stage, key emails or calls, calendar events touched.

   If you can't tell what the artifacts are, ASK the user rather than forcing a git-shaped answer. Always also pull `list_recent` for memories written this session. Make each slot domain-appropriate.
2. **Sweep the span for decisions** (see Selection) — the whole session for a first checkpoint, since the last durable capture otherwise. Pull the verbatim decision turns across every topic. Source the quotes from the session transcript where the client exposes one, not from working context (see Verbatim discipline) — reconstructed quotes drift.
3. **Compose the body** (slots below). Distinguish done from believed — a witnessed decision is dated and attributed; anything not directly observed is "the user said" / "believed to be."
4. **Write a NEW memory** — do not mutate a prior checkpoint. `remember(type: "observation", metadata: { kind: "checkpoint", scope: <workstream>, salient: <bool> })`. Append is correct: the temporal graph co-exists dated snapshots and recall resolves recency (constraint #32768), so a checkpoint series is a lossless progress trail. Link the prior checkpoint of the same `scope` (and any memory whose coverage you skipped) with the `[anchor](vertiso-memory://memories/{id})` format — link for lineage, do not claim supersession (observation↔observation do not supersede; the reader resolves recency).
5. **Report** the new checkpoint id, its mode, the topics swept, and the one-line "next." Render every memory reference shown to the USER as a clickable web link — `[#{id}](https://memory.vertiso.ai/memories/{id})` — never a bare `#id` (GitHub-flavored markdown autolinks `#nnnn` to a GitHub issue). The `vertiso-memory://` scheme belongs INSIDE memory bodies for graph edges (step 4); the `https://memory.vertiso.ai/memories/{id}` web URL is for chat/report output.

## The body — handoff's six slots, expanded for resume

1. **Working on** — the subject / goal (or goals, if the span was multi-topic).
2. **Decisions + WHYs** — the session's decisions, each with the verbatim words that drove it (attributed to who spoke — the user's exact framing plus any agent turn that carried the context/insight) and the reason. **Group by topic when the span covered several**; capture every topic's decisions, do not let the latest crowd out earlier ones. This is the expanded slot and the point of the skill.
3. **Where it stands** — the current state in the workstream's own terms. Software: uncommitted working-tree (files touched, staged/unstaged), branch / PR / gate, what's green / red / untested. Otherwise: the artifact's current revision + what's done / in-progress / blocked — a draft at v3 with §2 unwritten; a design approved but not yet exported; a prototype passing 2 of 5 tests; a deal at term-sheet. Whatever tells a cold reader the work's exact position.
4. **Mental model in play** — the approach, the invariant held, the hypothesis being tested. What a cold reader would otherwise re-derive.
5. **Next** — the exact next action, concrete enough to resume without re-deriving: the command to run + `file:line` for code, or the specific artifact and step otherwise ("open the deck, redo the pricing chart on slide 7"; "call the supplier re: the tolerance"; "export the board to PDF and send to the client").
6. **Open questions / blockers** — what is waiting on the user, what is being debugged.
7. **Salient captures + skipped coverage** — links to salient checkpoints since the last routine one, and to any memory whose decisions were skipped as already-captured.
8. **Verify before operating** — standing advisory: re-check slot 3 against current reality and re-confirm any slot-2 decision before acting; this snapshot is a point in time.

Salient-mode body collapses to the single moment: the flagged decision/ah-ha (verbatim) + its why + where it leaves the work + the next step. Written immediately.

## Shared engine

handoff and wrap-up use this skill to **gather the past context** — its Procedure steps 1-2 (gather + retrospective sweep = the attributed verbatim decisions + where-it-stands state). That gathered context FILLS one part of each wrapper's body; the wrapper then composes its OWN remaining slots on top and writes through its own verb. Checkpoint gathers the past; the wrappers build the rest on it — checkpoint's body does NOT replace a wrapper's slots.

**The transfer is VERBATIM.** The attributed quotes and the detailed state snapshot come across intact — the wrapper carries checkpoint's captured block word-for-word into its slot, it does NOT paraphrase, compress, or re-summarize it. That is the whole point: the verbatim that a hand-summarized handoff or wrap-up would lose is exactly what checkpoint preserves. Build your own slots around that preserved block; never distill it.

- **checkpoint** composes its full body (all slots) and writes/links a new checkpoint memory (this skill).
- **handoff** takes the gathered context into its "What happened" / "Where it stands" slots, builds its forward slots (Next, Open questions, Verify), and writes via the `handoff` verb (claimable resume protocol).
- **wrap-up** takes the gathered context into its "Decisions + WHYs" slot, builds its terminal slots (What shipped / closed / Next steps), writes via `remember`, then archives finished intents and creates follow-on intents.

Factor the *gather*, not the write — each caller composes its own body and persists through its own verb.

## Authoring honesty

A checkpoint is trusted only if a claim and a verified fact do not look identical. Verbatim quotes must be actual quotes — do not fabricate or clean up the user's words. Mark anything not directly observed. A slot-5 "next" with no basis, or a slot-2 decision that was never witnessed, poisons the resume.
