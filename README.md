# Network Monitor

A Noctalia Shell plugin that shows network speed and listening ports in one bar capsule, styled like the built-in widgets.

- **Bar:** `↓ rx  ↑ tx │ 🔌 count`. Left click opens the panel, right click opens a menu, middle click refreshes.
- **Panel:** a live traffic graph and the list of listening ports. Hover a row to open it in a browser or stop its process. Stopping a process owned by another user goes through `pkexec`.
- **IPC:** `qs -c noctalia-shell ipc call plugin:network-monitor toggle` (or `refresh`).

Requires `ss` (iproute2). Stopping root-owned ports needs `fuser` (psmisc) and a polkit agent.

Check the `ss` parser with `node scripts/parse-check.mjs`.
