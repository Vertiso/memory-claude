# Vertiso Memory for Claude Code

Official Claude Code plugin for Vertiso Memory: one-step install of the remote,
user-owned memory MCP server plus the session skills. Durable recall, hybrid
search, and cross-session handoffs and checkpoints, with browser OAuth and no
API key to paste.

> This repository is **generated** and published automatically from the Vertiso
> Memory source repository. The `vertiso-memory/` plugin and
> `.claude-plugin/marketplace.json` are overwritten on every publish, so do not
> hand-edit them. This `README.md` and `LICENSE` are seeded once and then
> maintained here by hand.

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

## Requirements

- The **MCP server and skills work on their own** — no local binary needed.
- The optional **SessionStart hook** calls the `vmem` CLI if it is on `PATH`
  (install via `curl -fsSL https://memory.vertiso.ai/install.sh | sh`). Without
  the CLI the hook is a silent no-op; memory still works through the MCP server
  and the `hello` tool.

## License

MIT. See [LICENSE](LICENSE). Copyright (c) 2026 Vertiso Corporation.

## Documentation

Full install and connection docs: https://memory.vertiso.ai/docs/install
