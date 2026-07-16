---
name: handoff-resume
description: >-
  Use at session start when hello reports open handoffs, or when the user runs
  /handoff-resume — finds open handoffs, claims the chosen one, and reconciles
  it against current reality before resuming work.
---

# Handoff Resume

Resume a prior session from a handoff — verifying before operating.

**Announce:** "Using the handoff-resume skill to pick up a prior session."

## When to use

- The user runs `/handoff-resume`.
- `hello` reported open handoffs at session start.

## Procedure

1. **Call `handoff_resume`** (the MCP tool, or `vmem handoff-resume`) with no
   `claim` argument — this returns the live set of open handoffs.
2. **Branch on the count:**
   - **0** — nothing to resume; stop here.
   - **1** — carry it forward.
   - **>1** — interactive pick: present one option per handoff (its scope, the
     writing agent, a one-line state), pre-flagging any that look stale; let
     the user choose.
3. **Claim the chosen handoff** — call `handoff_resume` again with
   `claim: <id>`. Claiming archives it so a parallel session resuming
   concurrently cannot re-grab it.
4. **Do the recipient diligence the handoff's slot-6 advisory calls for,
   before operating.** Verify the slot-3 "where it stands" state against
   current reality. Re-confirm any decision or approval recorded in slot 2.
   The handoff carries its claims honestly, but the world may have moved.
5. **Present** the reconciled picture and the concrete pick-up point to the user.

## Why verify

The handoff author distinguished what was done from what was believed, but
cannot know what changed since. Verification is the recipient's job — do it
before you operate, not after.
