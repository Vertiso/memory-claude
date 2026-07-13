# Vertiso Memory for Claude Code

Official Claude Code plugin for Vertiso Memory: one-step install of the remote,
user-owned memory MCP server plus the session skills. Durable recall, hybrid
search, and cross-session handoffs and checkpoints, with browser OAuth and no
API key to paste.

> This repository is **generated** and published automatically from the Vertiso
> Memory source repository. The `vertiso-memory/` plugin and
> `.claude-plugin/marketplace.json` are overwritten on every publish, so do not
> hand-edit them. The root `README.md` and `LICENSE` are generated too, so make
> changes upstream.

## Install

```text
/plugin marketplace add Vertiso/memory-claude
/plugin install vertiso-memory@vertiso
```

Installs the remote MCP server (`https://memory.vertiso.ai/mcp`), the four
session skills (`checkpoint`, `handoff`, `handoff-resume`, `wrap-up`, namespaced
as `/vertiso-memory:<skill>`), and a SessionStart primer hook. Authentication is
OAuth 2.1 with Dynamic Client Registration and PKCE, discovered from the
endpoint; sign-in happens in the browser, with no API key to paste.

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

The hook is quiet and always non-blocking during normal startup. To verify a
new plugin installation, launch a fresh Claude Code session with diagnostics:

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
