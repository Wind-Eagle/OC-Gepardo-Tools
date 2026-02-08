local smart_require = require("util.smart_require")

local Requester = smart_require.reload("lib.network.requester")

local launch = smart_require.reload("util.launch")

local thread = require("thread")

local requester = nil

local function main()
    requester = Requester:new(80, function(data, _, _, srcAddress, srcPort, requestId)
        requester:sendResponse(srcAddress, srcPort, requestId, {isCatCute = data["catName"] .. " is a cute cat", requestType = "cat_cuteness_response"})
        end
    )
    requester:start()
    thread.current():suspend()
end

local function onExit()
    if requester then
        requester:delete()
    end
end

launch.launch(main, onExit)
