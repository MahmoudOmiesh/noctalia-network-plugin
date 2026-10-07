// Extracts parseListeners() from Main.qml verbatim and checks it against known `ss -tulnpH` output.
import { readFileSync } from "node:fs";
import { deepStrictEqual } from "node:assert/strict";

const qml = readFileSync(new URL("../Main.qml", import.meta.url), "utf8");
const source = qml.match(/^  function parseListeners\([\s\S]*?\n  \}$/m)?.[0];
if (!source) throw new Error("parseListeners() not found in Main.qml");
const parseListeners = new Function(`${source}\nreturn parseListeners;`)();

const sample = `tcp LISTEN 0 511 0.0.0.0:3773 0.0.0.0:* users:(("t3code",pid=4104,fd=3))
tcp LISTEN 0 4096 127.0.0.53%lo:53 0.0.0.0:*
tcp LISTEN 0 4096 [::]:5355 [::]:*
udp UNCONN 0 0 [fe80::dff3:6e2f:8009:2255]%enp34s0:546 [::]:*
tcp LISTEN 0 511 0.0.0.0:3000 0.0.0.0:* users:(("node",pid=5000,fd=20))
tcp LISTEN 0 511 [::]:3000 [::]:* users:(("node",pid=5000,fd=21))
tcp LISTEN 0 511 127.0.0.1:6463 0.0.0.0:* users:(("electron",pid=1582,fd=144))
tcp LISTEN 0 511 [::1]:6463 [::]:* users:(("electron",pid=1582,fd=145))
`;

const t3code = { key: "tcp:3773:4104", port: 3773, proto: "tcp", pid: 4104, process: "t3code", addresses: ["0.0.0.0"], localOnly: false };
const node = { key: "tcp:3000:5000", port: 3000, proto: "tcp", pid: 5000, process: "node", addresses: ["0.0.0.0", "::"], localOnly: false };
const electron = { key: "tcp:6463:1582", port: 6463, proto: "tcp", pid: 1582, process: "electron", addresses: ["127.0.0.1", "::1"], localOnly: true };
const resolved = { key: "tcp:53:0", port: 53, proto: "tcp", pid: 0, process: "", addresses: ["127.0.0.53"], localOnly: true };
const llmnr = { key: "tcp:5355:0", port: 5355, proto: "tcp", pid: 0, process: "", addresses: ["::"], localOnly: false };
const dhcp = { key: "udp:546:0", port: 546, proto: "udp", pid: 0, process: "", addresses: ["fe80::dff3:6e2f:8009:2255"], localOnly: false };

const cases = [
  ["defaults", { includeUdp: false, hideSystemPorts: true, onlyOwnProcesses: false }, [node, t3code, electron, llmnr]],
  ["no filters", { includeUdp: true, hideSystemPorts: false, onlyOwnProcesses: false }, [node, t3code, electron, resolved, dhcp, llmnr]],
  ["only own processes", { includeUdp: true, hideSystemPorts: false, onlyOwnProcesses: true }, [node, t3code, electron]],
  ["empty input", { includeUdp: true, hideSystemPorts: false, onlyOwnProcesses: false }, [], ""],
];

for (const [name, opts, expected, text = sample] of cases) {
  deepStrictEqual(parseListeners(text, opts), expected, name);
  console.log(`ok - ${name}`);
}
