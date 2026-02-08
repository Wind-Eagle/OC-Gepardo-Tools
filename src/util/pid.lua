local pid = {}

local process = require("process")

local smart_require = require("util.smart_require")
local random = smart_require.reload("util.random")

function pid.getPid()
    local processInfo = process.info()["data"]
    if not processInfo["_getPidInternal"] then
        processInfo["_getPidInternal"] = random.generateUid()
    end
    return processInfo["_getPidInternal"]
end

return pid
