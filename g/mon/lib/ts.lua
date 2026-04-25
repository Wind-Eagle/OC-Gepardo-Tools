local timeseries = {}

local function sortByTimestamp(ts)
  table.sort(ts, function(a, b)
      return a.timestamp < b.timestamp
  end)
end

function timeseries.pushBack(ts, value, timestamp)
  ts[#ts + 1] = {value = value, timestamp = timestamp}
  sortByTimestamp(ts)
end

function timeseries.trunc(ts, cnt)
  local n = #ts
  for i = 1, cnt do
    ts[i] = ts[i + n - cnt]
  end
  for i = cnt + 1, n do
    ts[i] = nil
  end
end

function timeseries.tail(ts, cnt)
  local tsNew = {}
  for key, value in pairs(ts) do
    tsNew[key] = value
  end
  timeseries.trunc(tsNew, cnt)
  return tsNew
end

function timeseries.first(ts)
  return ts[1]
end

function timeseries.last(ts)
  return ts[#ts]
end

function timeseries.len(ts)
  return #ts
end

function timeseries.sum(ts)
  local sum = 0
  for _, value in pairs(ts) do
    sum = sum + value
  end
  return sum
end

function timeseries.deriv(ts)
  local n = #ts
  if n < 2 then
    return 0
  end

  local sum_t = 0
  local sum_v = 0
  local sum_tt = 0
  local sum_tv = 0

  for _, p in ipairs(ts) do
    local t = p.timestamp
    local v = p.value
    sum_t = sum_t + t
    sum_v = sum_v + v
    sum_tt = sum_tt + t * t
    sum_tv = sum_tv + t * v
  end

  local denominator = n * sum_tt - sum_t * sum_t
  if denominator == 0 then
    return 0
  end

  local slope = (n * sum_tv - sum_t * sum_v) / denominator
  return slope
end

return timeseries
