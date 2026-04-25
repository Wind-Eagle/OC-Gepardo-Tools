local tsModule = {}

local function sortByTimestamp(ts)
  table.sort(ts, function(a, b)
      return a.timestamp < b.timestamp
  end)
end

function tsModule.pushBack(ts, value, timestamp)
  ts[#ts + 1] = {value = value, timestamp = timestamp}
  sortByTimestamp(ts)
end

function tsModule.trunc(ts, cnt)
  local n = #ts
  for i = 1, cnt do
    ts[i] = ts[i + n - cnt]
  end
  for i = cnt + 1, n do
    ts[i] = nil
  end
end

function tsModule.tail(ts, cnt)
  local tsNew = {}
  for key, value in pairs(ts) do
    tsNew[key] = value
  end
  tsModule.trunc(tsNew, cnt)
  return tsNew
end

function tsModule.first(ts)
  return ts[1]
end

function tsModule.last(ts)
  return ts[#ts]
end

function tsModule.len(ts)
  return #ts
end

function tsModule.sum(ts)
  local sum = 0
  for _, value in pairs(ts) do
    sum = sum + value
  end
  return sum
end

function tsModule.deriv(ts)
  return tsModule.last(ts)
end

return tsModule
