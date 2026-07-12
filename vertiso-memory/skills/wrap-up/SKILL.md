---
name: wrap-up
description: Use at the end of a session whose work has stabilized — closes out completed work in Vertiso Memory (archives finished intents), records the stable state, and ensures every deferred follow-on becomes a tracked vmem intent so nothing gets dropped. Distinct from handoff (continuation) and goodbye (session lifecycle).
---

# Wrap-up

Close out a finished session: archive the completed work in Vertiso Memory, journal the stable state, and ensure every deferred follow-on has a tracked vmem intent.

**Announce:** "Using the wrap-up skill to close out this session."

## When to use

- The user runs `/wrap-up`.
- A session's work has stabilized — shipped, merged, decided — with no continuation point. (If there is one, use `handoff` instead.)
- Intents the session touched are now done, but nobody has archived them.
- The session is winding down with concrete follow-ons that need to land in vmem before they evaporate.

## Distinct from related skills

- **`handoff`** — work continues and the next agent needs a pick-up point. Wrap-up is the opposite: work ends, nothing to resume.
- **`goodbye`** — the vmem session-lifecycle close. Orthogonal: a wrap-up may run before `goodbye`, or stand alone mid-day when a workstream finishes.

## Procedure

1. **Gather the past context via the checkpoint skill.** Follow the `checkpoint` skill's Procedure steps 1-2 — gather from the workstream's own artifacts (checkpoint's gather step carries the domain palette: software is `git log` / `git status` / `gh pr`, but match the domain — a PRD, a deck, CAD revisions, a signed doc; not git by default), plus `list_recent` for memories written this session and the user's explicit "done" / "shipped" / "delivered" signals; then retrospective-sweep the whole span for the attributed verbatim decisions (who said what). This gathered context FILLS wrap-up's "Decisions + WHYs" slot **verbatim** — carry checkpoint's attributed quotes and detailed snapshot across word-for-word, do NOT summarize them — and informs "Worked on" / "Stable state". Wrap-up's other slots — What shipped, What closed, Next steps — BUILD on it, they are not replaced by checkpoint. Do NOT invoke the checkpoint skill itself (that writes a checkpoint memory) — reuse its gather + sweep. Summarizing the verbatim away is the exact failure mode that motivated the shared engine.
2. **Identify archival candidates.** For each `intent` the session touched: a witnessed completion event (PR merged AND the intent's full scope shipped, ticket resolved, user confirmation) → propose archive. Partially shipped or broader-scope → do not. Uncertain → ask, don't guess.
3. **Resolve next-step linkage.** For each slot-7 item: link an existing intent if one matches; if none exists and the item is concrete, actionable, and beyond a single session, propose a new intent. Transient items (one-off cleanup, naming fixes) get an inline `[transient]` annotation instead of an intent.
4. **Confirm before writing or archiving.** Show the user the proposed new-intent list (title + one-line description each) and the candidate archive list (one-line rationale each), then wait for explicit go-ahead — the user may pick a subset. Never create or archive without confirmation; reversible does not mean unilateral.
5. **Create the confirmed intents** via `remember(type: "intent", ...)`, capturing their IDs for slot 7.
6. **Write the wrap-up memory** via `remember`: pass `type: "observation"` and `metadata: { kind: "wrap-up", scope: <the session's primary scope, a git branch or project name, if any> }`. (`remember` has no top-level `scope` argument; scope travels inside `metadata`.) Cite evidence inline (the artifact reference — a commit SHA / PR URL for code, or the published / signed / delivered artifact otherwise; a memory ID) and use the `[anchor](vertiso-memory://memories/{id})` link format for every vmem cross-reference so the graph picks them up.
7. **Archive the confirmed intents** via `archive_memory`, one call each, passing the intent `id`. `archive_memory` has no free-text reason field, so the close-out's traceability lives in slot 4 ("What closed") of the body above — it names each archived intent and the wrap-up that closed it.
8. **Report** using the format below. Every actionable item must reach the user with its intent link or its transient rationale.

## The body

Checkpoint's gather (step 1) fills the **Decisions + WHYs** slot and informs Worked-on / Stable state. The rest are wrap-up's own terminal slots — What shipped, What closed, Next steps — built on that context, not replaced by it.

1. **Worked on** — what this session was about, in a sentence or two.
2. **Decisions + WHYs (attributed verbatim)** — the session's decisions with the exact words that drove them, attributed to who spoke (the user's framing plus any agent turn that carried the context/insight), per checkpoint's verbatim discipline. Do NOT summarize these away — this is the slot a wrap-up historically dropped.
3. **What shipped / delivered** — concrete artifacts, each with evidence. Software: commit SHAs, PR numbers + URLs, migrations run, deploys, memories written. Otherwise the delivered artifact itself is the evidence: a published deck, a signed contract, a released CAD revision, a sent proposal, a delivered mockup. No citation (or artifact reference), no entry.
4. **What closed** — intents archived in this wrap-up, each with the witnessed event that justifies it (a PR merged, a deliverable accepted, a decision ratified, a milestone hit — e.g. "archive #4954 — PR #147 merged, AiCall + CostRate live in production"). One line each.
5. **Stable state** — the state of the world after this session: what's live / final / in-flight, and the equivalent for the domain (deployed and on `main`; or published / signed / shipped / still pending), what assumptions hold. The context a future agent would otherwise have to reconstruct.
6. **Worth flagging** — non-actionable notes: memories written this session (linked), decisions that changed how we work, lessons captured. Not follow-ons — those go in slot 7.
7. **Next steps** — actionable follow-ons. Per line: `- [intent title](vertiso-memory://memories/{id}) — what to do next`. A transient item not worth an intent gets a `[transient]` prefix and a reason instead of a link.

## Report format

```
## Wrap-up

- **Wrap-up memory**: vmem #{id}
- **Intents archived**: {count} — {#id (title), …, or "none"}
- **Intents created**: {count} — {#id (title), …, or "none"}

## Next steps ({n})

1. [title](vertiso-memory://memories/{id}) — {what to do}
2. [transient] {item} — {why no intent}
```

Every slot-7 item appears here with its intent link or its transient rationale. An item the user declined to track gets a `[deferred — no intent created]` annotation so the choice stays visible.

## Authoring honesty

A wrap-up's value is the archive action, the intent-creation discipline, and a record future sessions can trust as a primary source. Sloppy or dishonest authoring poisons all three.

- "Shipped" needs evidence on the same line — no bare claims.
- "Closed intent #X" needs a witnessed event (a PR merge, a user confirmation, an observable proxy), not chat narrative.
- Say "inferred" or "believed to be" for anything you did not directly observe.
- A slot-7 item with neither an intent link nor a `[transient]` annotation is a drop risk — never leave one without one of the two.
