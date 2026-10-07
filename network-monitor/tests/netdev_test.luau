--!nonstrict

local netdev = require("../netdev.luau")

return function(report)
  local before = netdev.parse([[Inter-| Receive | Transmit
  eth0: 1000 0 0 0 0 0 0 0 2000 0 0 0 0 0 0 0
  lo: 5000 0 0 0 0 0 0 0 5000 0 0 0 0 0 0 0
  veth0: 1000 0 0 0 0 0 0 0 2000 0 0 0 0 0 0 0
]])
  local current = netdev.parse([[Inter-| Receive | Transmit
  eth0: 5000 0 0 0 0 0 0 0 3000 0 0 0 0 0 0 0
  lo: 9000 0 0 0 0 0 0 0 9000 0 0 0 0 0 0 0
  veth0: 5000 0 0 0 0 0 0 0 3000 0 0 0 0 0 0 0
]])
  local physical = { eth0 = true, lo = false, veth0 = false }
  local rx, tx = netdev.rates(current, before, 2, physical)
  assert(rx == 2000 and tx == 500, `expected 2000/500, got {rx}/{tx}`)
  report("ok - physical interface deltas")
  rx, tx = netdev.rates(before, current, 2, physical)
  assert(rx == 0 and tx == 0, "counter resets must not produce negative rates")
  report("ok - counter reset")
  rx, tx = netdev.rates(current, {}, 2, physical)
  assert(rx == 0 and tx == 0, "a new interface needs a baseline")
  report("ok - first sample")
  rx, tx = netdev.rates(current, before, 0, physical)
  assert(rx == 0 and tx == 0, "zero elapsed time must not divide by zero")
  report("ok - zero elapsed time")
end
