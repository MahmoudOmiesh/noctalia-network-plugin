--!nonstrict

export type Counters = { [string]: { rx: number, tx: number } }

local M = {}

function M.parse(text: string): Counters
  local counters = {}
  for line in string.gmatch(text, "[^\n]+") do
    local name, fields = string.match(line, "^%s*([^:]+):%s*(.*)$")
    if name == nil then
      continue
    end
    local values = {}
    for value in string.gmatch(fields, "%S+") do
      table.insert(values, tonumber(value))
    end
    if #values >= 16 then
      counters[name] = { rx = values[1], tx = values[9] }
    end
  end
  return counters
end

function M.rates(current: Counters, previous: Counters, seconds: number, physical: { [string]: boolean }): (number, number)
  local rx, tx = 0, 0
  if seconds <= 0 then
    return rx, tx
  end
  for name, counters in current do
    local before = previous[name]
    if physical[name] and before ~= nil then
      rx += math.max(0, counters.rx - before.rx) / seconds
      tx += math.max(0, counters.tx - before.tx) / seconds
    end
  end
  return rx, tx
end

return M
