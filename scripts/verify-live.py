#!/usr/bin/env python3
import json
import os
from pathlib import Path
import re
import signal
import socket
import subprocess
import tempfile
import time

PLUGIN = "mahmoudomiesh/network-monitor:scanner"


def dispatch(event, path=None):
    args = ["noctalia", "msg", "plugin", PLUGIN, "all", event]
    if path is not None:
        args.append(str(path))
    result = subprocess.run(args, check=True, capture_output=True, text=True)
    if result.stdout.startswith("error:"):
        raise RuntimeError(result.stdout.strip())


def read_result(event, path):
    path.unlink(missing_ok=True)
    dispatch(event, path)
    deadline = time.monotonic() + 5
    while not path.exists():
        if time.monotonic() >= deadline:
            raise TimeoutError(f"{event} did not write {path}")
        time.sleep(0.05)
    return path.read_text()


def wait_for(predicate):
    deadline = time.monotonic() + 5
    while not predicate():
        if time.monotonic() >= deadline:
            raise TimeoutError("listener state did not converge")
        time.sleep(0.1)


with tempfile.TemporaryDirectory(prefix="netmon-check-") as directory:
    root = Path(directory)
    output = read_result("selftest", root / "selftest.txt")
    print(output, end="")
    assert "not ok" not in output and len(output.splitlines()) == 22, output
    with socket.socket() as reservation:
        reservation.bind(("127.0.0.1", 0))
        port = reservation.getsockname()[1]
    pid = None
    with (root / "server.log").open("w") as log:
        subprocess.run(
            ["setsid", "-f", "python3", "-m", "http.server", str(port), "--bind", "127.0.0.1"],
            check=True, stdout=log, stderr=log,
        )
    try:
        def find_pid():
            global pid
            output = subprocess.check_output(["ss", "-tulnpH"], text=True)
            for line in output.splitlines():
                if re.search(rf"127\.0\.0\.1:{port}\s", line):
                    pid = int(re.search(r"pid=(\d+)", line)[1])
                    return True
            return False

        wait_for(find_pid)
        dispatch("refresh")
        expected = {
            "key": f"tcp:{port}:{pid}", "port": port, "proto": "tcp", "pid": pid,
            "process": "python3", "addresses": ["127.0.0.1"], "localOnly": True,
        }

        def listener_visible():
            state = json.loads(read_result("status", root / "status.json"))
            return expected in state["listeners"] and not state["scanError"]

        wait_for(listener_visible)
        print("ok - live loopback server appears after refresh")
        os.kill(pid, signal.SIGTERM)
        wait_for(lambda: not Path(f"/proc/{pid}").exists())
        dispatch("refresh")

        def listener_removed():
            state = json.loads(read_result("status", root / "status.json"))
            return all(row["key"] != expected["key"] for row in state["listeners"])

        wait_for(listener_removed)
        print("ok - stopped server disappears after refresh")
        pid = None
    finally:
        if pid is not None:
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
