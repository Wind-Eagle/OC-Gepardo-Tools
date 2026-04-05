local times = {}

local os = require('os')

function times.ticksFromEpoch()
  return math.floor(os.time() / 60 / 60 * 1000 + 0.5)
end

return times
