local smart_require = require("util.smart_require")

local DNSService = smart_require.reload("netctrl.dns.service")
local launch = smart_require.reload("util.launch")

local shell = require("shell")

local function help()
    print("=" .. string.rep("=", 40))
    print("Wi-Fi point")
    print("=" .. string.rep("=", 40))
    print("Usage: ./main.lua --data=<data path>")
end

local dataPath = nil
local _, options = shell.parse(...)

for argKey, argValue in pairs(options) do
    if not argValue then break end

    if argKey == "help" then
        help()
        os.exit(0)
    elseif argKey == "data" then
        dataPath = argValue
    end
end

local service = nil

local function main()
    service = DNSService:new(dataPath)
    service:start()
end

local function onExit()
    if service then
        service:delete()
    end
end

launch.launch(main, onExit)
