local time = require("util.time")

local random = {}

function random.generateUid()
    return require("uuid").next():sub(1, 8) .. "-" .. tostring(time.getTicksFromEpoch())
end

return random
