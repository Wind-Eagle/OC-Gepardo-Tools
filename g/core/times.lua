local times = {}

local os = require('os')

function times.ticksFromEpoch()
  return math.floor(os.time() / 60 / 60 * 1000 + 0.5)
end

function times.daysFromEpoch()
  return math.floor((times.ticksFromEpoch() - 6000) / 24000)
end

return times
