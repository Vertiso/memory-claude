# Vertiso Memory for Claude

Official plugin for Claude.ai web, Claude Desktop, and Claude Code CLI: one
install of the remote, user-owned Vertiso Memory MCP server plus the session
skills. Durable recall, hybrid search, and cross-session handoffs and
checkpoints, with browser OAuth and no API key to paste.

## Install the complete plugin

For Claude.ai web chat, Claude Desktop Chat, and Cowork, add Vertiso's public
plugin marketplace:

```text
Customize → Plugins → Personal plugins → + → Add marketplace
Choose Add from a repository
Repository: https://github.com/Vertiso/memory-claude
Sync, open Vertiso Memory, then select Install
```

This installs the remote MCP server and the four session skills (`checkpoint`,
`handoff`, `handoff-resume`, and `wrap-up`, namespaced as
`/vertiso-memory:<skill>`).

## Claude Desktop

Claude Desktop is the unified app with Chat, Cowork, and Code tabs. The plugin
above works in Chat and Cowork.

In the Code tab, select **+ → Plugins → Add plugin**, then install Vertiso
Memory from the configured marketplace.

## Claude Code CLI

Install the same plugin from the terminal client:

```text
/plugin marketplace add Vertiso/memory-claude
/plugin install vertiso-memory@vertiso
```

Start a new Claude Code CLI session after installation. Authentication is OAuth
2.1 with Dynamic Client Registration and PKCE, discovered from the endpoint;
sign-in happens in the browser, with no API key to paste.

## Recommended: reinforce session bootstrap

The plugin includes an optional SessionStart hook. It invokes `vmem hello` when
`vmem` is on `PATH` and is otherwise a silent no-op. The bootstrap instruction
below works across Claude surfaces and calls the same Vertiso Memory `hello`
tool at the start of each session:

<!-- BEGIN bootstrap-instruction -->
> Vertiso Memory (vmem) is my persistent memory across every tool and session.
>
> - Call the `hello` tool at the start of every session. Treat its primer
>   as authoritative context, not a suggestion.
> - `recall` before planning or answering anything that may depend on
>   earlier context. Look it up instead of asking me to repeat it.
> - `remember` durable decisions, preferences, constraints, and project
>   state the moment they land. `update_memory` rather than writing a
>   near-duplicate.
> - Offer a handoff before the session ends, compacts, or moves to
>   another tool.
<!-- END bootstrap-instruction -->

## Memory and privacy

Vertiso Memory stores information you choose to preserve for future recall. When
you invoke `checkpoint`, `handoff`, or `wrap-up`, you ask your AI client to
send selected conversation and work context to Vertiso Memory. Captures may
include attributed verbatim excerpts when exact wording matters.

The marketplace plugin does not automatically upload complete conversations and
does not install a pre-compaction transcript hook. After you invoke a memory
skill, it completes the requested capture without asking you to approve each
individual excerpt.

You can review, export, archive, and permanently delete stored memories at
https://memory.vertiso.ai. Memory skills are instructed to strip detected
secrets before composing a capture and never echo them back, but automated
detection can miss sensitive material. Do not share passwords, API keys,
authentication tokens, payment information, illegal or illicit materials, or
information you are not authorized to store. Use appropriate judgment before
including confidential, private, sensitive, or third-party information.

Full memory-handling and control details:
https://memory.vertiso.ai/trust

## Requirements

- The **MCP server and skills work on their own** — no local binary needed.
- The optional **SessionStart hook** calls the `vmem` CLI if it is on `PATH`
  (see the [CLI installation options](https://memory.vertiso.ai/docs/install)).
  Without the CLI the hook is a silent no-op; memory still works through the
  MCP server and the `hello` tool.

## Verify the optional primer

The hook is quiet and always non-blocking during normal startup. To verify the
plugin-bundled hook, ensure `vmem` is on `PATH`, then launch a fresh Claude Code
CLI session with diagnostics:

```sh
VMEM_SESSION_START_DIAGNOSTICS=1 \
  claude --debug-file /tmp/vertiso-memory-session-start.log
```

After the session starts, inspect the known log path from another terminal:

```sh
grep "Vertiso Memory SessionStart diagnostics" \
  /tmp/vertiso-memory-session-start.log
```

The hook reports one of three outcomes in the debug log:

- `attempted: vmem hello succeeded` verifies that the primer ran.
- `skipped: vmem was not found on PATH` means the optional CLI is absent.
- `attempted: vmem hello failed (exit N)` distinguishes an authentication,
  network, or service failure from the absent-CLI case.

Diagnostics do not change startup behavior: every outcome remains
non-blocking, and the MCP server remains available when the CLI is absent.

## Availability

Available worldwide except where prohibited by applicable law or unsupported
by our service providers.

## License

MIT. See [LICENSE](LICENSE). Copyright (c) 2026 Vertiso Corporation.

## Documentation

Full install and connection docs: https://memory.vertiso.ai/docs/install

## Support

Account, authentication, and deletion help:
https://memory.vertiso.ai/support

Security policy and private vulnerability reporting:
https://memory.vertiso.ai/security
