---
name: wrap-up
description: >-
  Close out stabilized work in Vertiso Memory when the user requests a wrap-up,
  invokes /wrap-up, or affirmatively accepts an agent's offer. Separately
  confirm any proposed follow-on creation or work closure — completing
  actions, archiving finished intents and projects — then record the stable
  state, so deferred follow-ons are tracked without unapproved state changes.
---

# Wrap-up

Close out a finished session: close the completed work in Vertiso Memory —
complete the actions that shipped, archive the intents and projects whose
full scope is done — journal the stable state, and ensure every deferred
follow-on is tracked — as a vmem ACTION (a concrete piece of work) or, for a
measurable outcome to achieve or maintain, an intent.

**Announce:** "Using the wrap-up skill to close out this session."

## Consent boundary

Invoking this skill at the user's request, or affirmatively accepting an
agent's offer to run it, authorizes one capture. Invocation authorizes the
wrap-up memory and its checkpoint-backed transcript gathering, including
selected attributed verbatim excerpts sent to Vertiso Memory. Once invoked, do
not ask a second permission question for that capture. It does not authorize
creating, completing, or archiving actions, intents, or projects; those
additional mutations retain the explicit confirmation step below.

Do not ask whether to write the wrap-up memory; the user's invocation already
authorized it. When follow-on or closure candidates exist, ask only whether
to create or close those named actions/intents/projects, and state that the
wrap-up memory will be written regardless. If both lists are empty, proceed
without another question.

One invocation does not grant standing authorization for later wrap-ups. Omit
and do not persist passwords, API keys, authentication tokens, payment
information, illegal or illicit materials, or sensitive third-party
information the user is not authorized to store.

### Secret stripping

Before composing the memory, inspect every selected source, including the
conversation, transcript, work artifacts, tool output, title, tags, and
metadata, for secrets. Treat passwords, API keys, bearer or refresh tokens,
OAuth codes, session cookies, private keys, recovery codes, and credentialed
connection strings as secrets.

Strip or redact any detected value before composing the memory. Never send the
original value to Vertiso Memory or copy it into a quote, title, tag, metadata,
link, or error detail. Do not echo the secret in the report; state only that
sensitive content was omitted. If sanitization would make the capture
meaningless, stop and ask the user for a sanitized replacement.

## When to use

- The user runs `/wrap-up`.
- The user asks for a wrap-up or affirmatively accepts an agent's offer.
- Stabilized work, completed actions / intents / projects, or concrete
  follow-ons are reasons to offer a wrap-up, not authorization to run it. If
  work continues, offer a `handoff` instead.

## Distinct from related skills

- **`handoff`** — work continues and the next agent needs a pick-up point.
  Wrap-up is the opposite: work ends, nothing to resume.
- **`goodbye`** — the vmem session-lifecycle close. Orthogonal: a wrap-up
  may run before `goodbye`, or stand alone mid-day when a workstream finishes.

## Procedure

1. **Gather the past context via the checkpoint skill.** Follow the
   `checkpoint` skill's Procedure steps 1-2 — gather from the workstream's own
   artifacts (checkpoint's gather step carries the domain palette: software is
   `git log` / `git status` / `gh pr`, but match the domain — a PRD, a deck,
   CAD revisions, a signed doc; not git by default), plus `list_recent` for
   memories written this session and the user's explicit "done" / "shipped" /
   "delivered" signals; then retrospective-sweep the whole span for the
   attributed verbatim decisions (who said what). This gathered context FILLS
   wrap-up's "Decisions + WHYs" slot **verbatim** — carry checkpoint's
   attributed quotes and detailed snapshot across word-for-word, do NOT
   summarize them — and informs "Worked on" / "Stable state". Wrap-up's other
   slots — What shipped, What closed, Next steps — BUILD on it, they are not
   replaced by checkpoint. Do NOT invoke the checkpoint skill itself (that
   writes a checkpoint memory) — reuse its gather + sweep. Summarizing the
   verbatim away is the exact failure mode that motivated the shared engine.
2. **Identify closure candidates — every completable work type.** Audit every
   action, intent, and project the session touched: `list_actions` and the
   primer's `open_actions` for actions (their ids are the `complete_action`
   ids, distinct from memory ids — each row also carries the `memory_id` it
   came from), `list_recent` for intents and projects, plus anything linked
   from the gathered context. Propose completion ONLY on a witnessed
   completion event; propose abandonment ONLY on the user's explicit
   statement that the item is dropped — never inferred from inactivity.
   Partially shipped or broader-scope → do not; uncertain → ask, don't guess.
   - **Action** → the work itself is done (the PR merged, the artifact
     delivered, the user said "done") → propose
     `complete_action(closed: true)`.
   - **Intent** → the measurable outcome is reached and the intent's full
     scope shipped → propose `archive_memory(complete: true)`.
   - **Project** → every piece of work in its scope is closed and nothing in
     scope remains open → propose `archive_memory(complete: true)`. Witness
     the scope — no single read covers it, so run all three:
     `list_actions(memory_id: <project id>, work: "open")` (only the actions
     cut from the project's own text); `list_actions(tags:
     ["project:<slug>"], work: "open")` and `list_recent(types: ["intent",
     "project"], tags: ["project:<slug>"], work: "open")` for tagged
     membership, where the project's tag is known; and, for every
     `memory_id` in the project's `get_memory` `references` /
     `referenced_by` (edge rows carry ids and titles, not status), a
     follow-up `get_memory` showing the item archived or its `work_status`
     closed. All empty → the scope is clear. An edge list at its 20-row cap,
     or a scope you cannot enumerate → uncertain → ask. Closing a project's
     child actions does NOT close the project: while any in-scope work is
     still incomplete the project stays active and only the finished
     children close.

   A parent — intent or project — is never archived over open children,
   as complete or as abandoned. When the user says a parent is done but its
   scope still holds open items, each open item becomes its own closure
   candidate and step 4 asks, per item: complete it too, drop it (abandon),
   or leave the parent open as incomplete.

   An item that is no longer actionable but was never finished is the
   abandoned shape and is proposed as such, never as completion:
   `complete_action(status: "abandoned")` for an action (never archive an
   action's root memory to abandon it — that hides the whole root);
   `archive_memory(complete: false)` for an intent or project. An
   intent-only audit is the failure mode this step exists to prevent:
   shipped actions left open, projects never examined.
3. **Resolve next-step linkage.** For each slot-7 item: link an existing
   intent or open action if one matches — never one on the closure
   candidate list; an item that still has a next step is not done. If none
   exists, propose a new
   **ACTION** (`remember(type: "action", ...)`) — a concrete piece of work to
   do. Propose a new **intent** ONLY for a measurable outcome to achieve or
   maintain (intents are goals, not to-dos; actions are the to-dos that serve
   them). Transient items (one-off cleanup, naming fixes) get an inline
   `[transient]` annotation instead of a memory.
4. **Confirm before memory mutations.** Show the user the proposed new
   action/intent list (title + one-line description each) and the closure
   candidate list (type, the call that will run, and the one-line witness
   each — the completion event, or, for an abandonment, the user's words
   that retired it; a parent with open children lists each child with its
   complete / drop / leave-open choice), then wait for explicit go-ahead;
   the user may pick a subset.
   If both lists are empty, no additional confirmation is needed. Frame this
   as confirmation only for the named changes, not for the wrap-up. Never
   create, complete, or archive memories without confirmation; invocation
   already authorized the wrap-up memory itself.
5. **Create the confirmed follow-ons** — `remember(type: "action", ...)` for
   work items, `remember(type: "intent", ...)` for measurable outcomes —
   capturing their IDs for slot 7.
6. **Close the confirmed work**, one call each, BEFORE writing the wrap-up
   so slot 4 records only what actually landed: `complete_action(id:,
   closed: true)` for an action (the action id from `list_actions` /
   `open_actions`, not the memory id) — pass `closed` explicitly: with
   neither `closed` nor `status` the call TOGGLES the current state and
   would reopen an action already closed elsewhere; `archive_memory(id:,
   complete: true)` for an intent or project — pass `complete` explicitly,
   never lean on the archive default to carry a completion claim;
   `complete_action(id:, status: "abandoned")` for a confirmed abandoned
   action and `archive_memory(id:, complete: false)` for a confirmed
   abandoned intent or project. Capture each result: build slot 4 only from
   successful receipts; a call that errors or times out is re-checked
   against current state before it is reported or retried — closed on
   re-check counts as a receipt, still open is reported open. Neither tool
   has a free-text reason field, so the close-out's traceability lives in
   slot 4 ("What closed") of the body below — it names each closed item,
   its type, its verb, and the witness that justified it; the wrap-up memory
   is itself the durable record of the close.
7. **Write the wrap-up memory** via `remember`: pass `type: "observation"` and
   `metadata: { kind: "wrap-up", scope: <the session's primary scope, a git
   branch or project name, if any> }`. (`remember` has no top-level `scope`
   argument; scope travels inside `metadata`.) Cite evidence inline (the
   artifact reference — a commit SHA / PR URL for code, or the published /
   signed / delivered artifact otherwise; a memory ID) and use the
   `[anchor](vertiso-memory://memories/{id})` link format for every vmem
   cross-reference so the graph picks them up.
8. **Report** using the format below. Every actionable item must reach the
   user with its action/intent link or its transient rationale.

## The body

Checkpoint's gather (step 1) fills the **Decisions + WHYs** slot and informs
Worked-on / Stable state. The rest are wrap-up's own terminal slots — What
shipped, What closed, Next steps — built on that context, not replaced by it.

1. **Worked on** — what this session was about, in a sentence or two.
2. **Decisions + WHYs (attributed verbatim)** — the session's decisions with
   the exact words that drove them, attributed to who spoke (the user's framing
   plus any agent turn that carried the context/insight), per checkpoint's
   verbatim discipline. Do NOT summarize these away — this is the slot a
   wrap-up historically dropped.
3. **What shipped / delivered** — concrete artifacts, each with evidence.
   Software: commit SHAs, PR numbers + URLs, migrations run, deploys, memories
   written. Otherwise the delivered artifact itself is the evidence: a
   published deck, a signed contract, a released CAD revision, a sent
   proposal, a delivered mockup. No citation (or artifact reference), no
   entry.
4. **What closed** — actions completed, intents / projects archived, and
   items abandoned in this wrap-up, each with its type, its verb, and the
   witness that justifies it. A completion carries the witnessed event (a PR
   merged, a deliverable accepted, a decision ratified, a milestone hit —
   e.g. "complete action #4960 — PR #147 merged"; "archive intent #4954 —
   AiCall + CostRate live in production, full scope shipped"); an
   abandonment carries the user's words that retired it, never a completion
   event (e.g. "abandon action #4971 — user: 'skip the CSV report'").
   One line each. A project listed here as completed means nothing in its
   scope remains open.
5. **Stable state** — the state of the world after this session: what's live /
   final / in-flight, and the equivalent for the domain (deployed and on
   `main`; or published / signed / shipped / still pending), what assumptions
   hold. The context a future agent would otherwise have to reconstruct.
6. **Worth flagging** — non-actionable notes: memories written this session
   (linked), decisions that changed how we work, lessons captured. Not
   follow-ons — those go in slot 7.
7. **Next steps** — actionable follow-ons. Per line:
   `- [action title](vertiso-memory://memories/{id}) — what to do next`. A
   transient item not worth a memory gets a `[transient]` prefix and a reason
   instead of a link.

## Report format

```
## Wrap-up

- **Wrap-up memory**: vmem #{id}
- **Actions completed**: {count} — {#id (title), …, or "none"}
- **Intents archived**: {count} — {#id (title), …, or "none"}
- **Projects archived**: {count} — {#id (title), …, or "none"}
- **Abandoned**: {count} — {type #id (title), …, or "none"}
- **Left open**: {count} — {type #id (title) — declined | close failed: <error>, or "none"}
- **Actions created**: {count} — {#id (title), …, or "none"}
- **Intents created**: {count} — {#id (title), …, or "none"}

## Next steps ({n})

1. [title](vertiso-memory://memories/{id}) — {what to do}
2. [transient] {item} — {why no tracked memory}
```

Every slot-7 item appears here with its action/intent link or its transient
rationale. An item the user declined to track gets a `[deferred — not
tracked]` annotation so the choice stays visible. A closure candidate the
user declined, or whose call failed, appears under **Left open** with its
reason.

## Authoring honesty

A wrap-up's value is the closure audit, the follow-on tracking discipline,
and a record future sessions can trust as a primary source. Sloppy or
dishonest authoring poisons all three.

- "Shipped" needs evidence on the same line — no bare claims.
- "Closed #X" — an action completed, an intent or project archived — needs a
  witnessed event (a PR merge, a user confirmation, an observable proxy), not
  chat narrative; an abandonment needs the user's explicit retirement, never
  an inference from inactivity. A project closed as completed additionally
  needs nothing in its scope still open.
- Say "inferred" or "believed to be" for anything you did not directly observe.
- A slot-7 item with neither an action/intent link nor a `[transient]`
  annotation is a drop risk — never leave one without one of the two.
