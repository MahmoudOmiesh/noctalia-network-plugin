# Network Monitor

A Noctalia v5 plugin for network speed, listening ports, and actions to open or stop a listener. See the [plugin README](network-monitor/README.md) for requirements, usage, settings, and IPC commands.

## Local installation

Run from this checkout:

```sh
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/noctalia/plugins"
ln -s "$PWD/network-monitor" "${XDG_DATA_HOME:-$HOME/.local/share}/noctalia/plugins/network-monitor"
noctalia msg config-reload
noctalia msg plugins enable mahmoudomiesh/network-monitor
```

Add the bar widget `mahmoudomiesh/network-monitor:indicator` in Settings. If the shell had the plugin enabled before its files existed, restart Noctalia to instantiate its entries. Luau edits then hot-reload.

The `network-monitor/` directory is the complete installable plugin and matches the community source layout. The QML implementation remains on `main` and at `v4-final`.

## Verification

With the plugin enabled in a running shell:

```sh
noctalia plugins lint network-monitor
noctalia msg plugin mahmoudomiesh/network-monitor:scanner all selftest
```

The selftest results appear in the shell log.
