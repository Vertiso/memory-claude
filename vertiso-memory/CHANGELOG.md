# Copyright © 2026. Copyright Vertiso Corporation, all rights reserved.

# Vertiso Memory plugin changelog

## 1.3.0 — 2026-08-28

- Add include: ["constraints"] to recall — task-scoped rule rows in the same
  call as context.
- Add synthesis: false to recall — retrieval facts only, answer omitted,
  confidence "none".
- Declare the constraints section and its row shape in recall's output schema.
- Teach the one-shot in the hello primer's constraints pointer.
- vmem recall gains --constraints and --no-synthesis.

## 1.2.0 — 2026-08-28

- Lead the hello primer with user_agent_instructions and pinned standing rules.
- Replace the primer's static contract with the vertiso-memory://contract
  resource.
- Ship count-honest intent and action indexes with overdue and undated tallies.
- Inherit user-asserted root tags onto fragments as deterministic taggings, so
  each rule carries its tags.
- Reuse a just-started agent session instead of minting one per hello,
  collapsing double-fired SessionStart hooks.
- Stamp primer_version: 2 so clients can detect the new shape.

## 1.1.1 — 2026-08-21

- Audit touched actions, intents, and projects for witnessed completion at
  wrap-up.
- Complete finished actions with complete_action; archive finished intents and
  projects with explicit completion.
- Keep a project active while any in-scope work remains open, closing only its
  finished children.
- Report actions completed and projects archived alongside intents archived.
- Refresh checkpoint skill references to the full closure set.

## 1.1.0 — 2026-08-05

- Teach the wrap-up skill to record durable follow-ons as actions instead of new
  intents.
- Reserve new-intent proposals for measurable outcomes to achieve or maintain.
- Refresh checkpoint skill references to the intents-and-actions work model.

## 1.0.0 — 2026-07-12

- Repair Codex marketplace discovery and document the complete install flow.
- Clarify full-plugin and MCP-only installation paths for Cursor and Codex.
- Add opt-in diagnostics for the Claude Code SessionStart hook.
- Advertise exact MCP input and output schemas on protocol 2025-06-18.
- Ship plugin payload documentation, licenses, changelogs, and release guards.
- Ship approved canonical V-in-circle artwork across web, Cursor, and Codex
  surfaces.
- Disclose global availability for adults 18+ where permitted and supported,
  subject to sanctions, export controls, and applicable AI and data laws.
- Disclose deliberate memory capture, verbatim preservation, and responsible-use
  controls.

## 0.2.1 — 2026-07-11

- Publish the initial Claude Code, Cursor, and Codex plugin packages.
