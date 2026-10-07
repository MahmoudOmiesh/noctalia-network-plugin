import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.System

Item {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property bool showSpeed: cfg.showSpeed ?? defaults.showSpeed ?? true
  readonly property bool showPorts: cfg.showPorts ?? defaults.showPorts ?? true
  readonly property int refreshInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 5
  readonly property bool hideSystemPorts: cfg.hideSystemPorts ?? defaults.hideSystemPorts ?? true
  readonly property bool onlyOwnProcesses: cfg.onlyOwnProcesses ?? defaults.onlyOwnProcesses ?? false
  readonly property bool includeUdp: cfg.includeUdp ?? defaults.includeUdp ?? false

  // Raw `ss` output is kept so filter changes re-apply without a new scan.
  property string ssOutput: ""
  readonly property var parsedListeners: parseListeners(ssOutput, {
                                                          "includeUdp": includeUdp,
                                                          "hideSystemPorts": hideSystemPorts,
                                                          "onlyOwnProcesses": onlyOwnProcesses
                                                        })
  property var listeners: []
  readonly property int listenerCount: listeners.length

  // Only publish a new array when something changed, so panel rows (and their hover state)
  // aren't recreated on every poll.
  onParsedListenersChanged: {
    if (JSON.stringify(parsedListeners) !== JSON.stringify(listeners)) {
      listeners = parsedListeners;
    }
  }

  Component.onCompleted: refresh()

  // Listener: { key, port, proto: "tcp"|"udp", pid (0 = unknown), process ("" = unknown), addresses, localOnly }
  // Rows sharing proto+port+pid (e.g. IPv4 and IPv6 binds) merge into one listener.
  function parseListeners(text, opts) {
    const isLoopback = address => address.startsWith("127.") || address === "::1";
    const byKey = {};
    const result = [];
    for (const line of text.split("\n")) {
      // Netid State Recv-Q Send-Q Local:Port Peer:Port [users:(("name",pid=N,fd=N))]
      const parts = line.trim().split(/\s+/);
      if (parts.length < 6)
        continue;
      const proto = parts[0];
      const local = parts[4];
      const sep = local.lastIndexOf(":");
      const port = parseInt(local.slice(sep + 1));
      if ((proto !== "tcp" && proto !== "udp") || sep < 0 || isNaN(port))
        continue;
      if (proto === "udp" && !opts.includeUdp)
        continue;
      if (opts.hideSystemPorts && port < 1024)
        continue;
      const owner = line.match(/users:\(\("(.+?)",pid=(\d+)/);
      const pid = owner ? parseInt(owner[2]) : 0;
      if (opts.onlyOwnProcesses && pid === 0)
        continue;
      const address = local.slice(0, sep).replace(/%.*$/, "").replace(/^\[|\]$/g, "");
      const key = proto + ":" + port + ":" + pid;
      let listener = byKey[key];
      if (!listener) {
        listener = byKey[key] = {
          "key": key,
          "port": port,
          "proto": proto,
          "pid": pid,
          "process": owner ? owner[1] : "",
          "addresses": [],
          "localOnly": true
        };
        result.push(listener);
      }
      if (!listener.addresses.includes(address)) {
        listener.addresses.push(address);
        listener.localOnly = listener.localOnly && isLoopback(address);
      }
    }
    return result.sort((a, b) => (a.pid === 0) - (b.pid === 0) || a.port - b.port);
  }

  function formatRate(bytesPerSecond) {
    return SystemStatService.formatSpeed(bytesPerSecond).replace(/([0-9.]+)([A-Za-z]+)/, "$1 $2") + "/s";
  }

  function refresh() {
    ssProcess.running = true;
  }

  function killListener(listener) {
    if (listener.pid > 0) {
      Quickshell.execDetached(["kill", String(listener.pid)]);
    } else {
      // Owner isn't visible to us (another user or root); polkit prompts for elevation.
      Quickshell.execDetached(["pkexec", "fuser", "-k", listener.port + "/" + listener.proto]);
    }
    killRefreshTimer.restart();
  }

  function openInBrowser(listener) {
    Quickshell.execDetached(["xdg-open", "http://localhost:" + listener.port]);
  }

  Process {
    id: ssProcess
    command: ["ss", "-tulnpH"]
    stdout: StdioCollector {
      onStreamFinished: root.ssOutput = this.text
    }
  }

  Timer {
    interval: root.refreshInterval * 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: killRefreshTimer
    interval: 600
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "plugin:network-monitor"

    function refresh() {
      root.refresh();
    }

    function toggle() {
      if (root.pluginApi) {
        root.pluginApi.withCurrentScreen(screen => {
                                           root.pluginApi.togglePanel(screen);
                                         });
      }
    }
  }
}
