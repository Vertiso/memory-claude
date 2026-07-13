# Copyright © 2026. Copyright Vertiso Corporation, all rights reserved.

if [ "${VMEM_SESSION_START_DIAGNOSTICS:-0}" = "1" ]; then
  if command -v vmem >/dev/null 2>&1; then
    vmem hello --source agent:claude-code --name "Claude Code"
    status=$?

    if [ "$status" -eq 0 ]; then
      printf "%s\n" \
        "Vertiso Memory SessionStart diagnostics attempted: vmem hello succeeded." \
        >&2
    else
      printf \
        "Vertiso Memory SessionStart diagnostics attempted: vmem hello failed (exit %s).\n" \
        "$status" >&2
    fi
  else
    printf "%s\n" \
      "Vertiso Memory SessionStart diagnostics skipped: vmem was not found on PATH." \
      >&2
  fi
elif command -v vmem >/dev/null 2>&1; then
  vmem hello --source agent:claude-code --name "Claude Code" 2>/dev/null
fi

exit 0
