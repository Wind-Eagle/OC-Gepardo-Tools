local smart_require = require("util.smart_require")

local smart_event = smart_require.reload("util.smart_event")
local launch = smart_require.reload("util.launch")

local NetctlService = smart_require.reload("netctrl.wifi.service")
local network = smart_require.reload("lib.network.network")

local thread = require("thread")
local shell = require("shell")
local event = require("event")

local function readFileToTable(filename)
    local t = {}
    for line in io.lines(filename) do
        local key, value = line:match("([^,]+),([^,]+)")
        t[key] = value
    end
    return t
end

local function help()
    print("=" .. string.rep("=", 40))
    print("Wi-Fi point")
    print("=" .. string.rep("=", 40))
    print("Usage: ./main.lua --config=<config path>")
end

local configPath = nil
local _, options = shell.parse(...)

for argKey, argValue in pairs(options) do
    if not argValue then break end

    if argKey == "help" then
        help()
        os.exit(0)
    elseif argKey == "config" then
        configPath = argValue
    end
end

if configPath == nil then
    print("No config path")
    help()
    return
end

local neighbours = readFileToTable(configPath)
local service = NetctlService:new(neighbours, network.network_internal_port)

local function main()
    local function onTimer(id)
        if id == "broadcast_timer" then
            service:broadcastAddress()
        end
    end

    smart_event.listen("broadcast_timer", onTimer, true)
    smart_event.listen("modem_message", function(...)
            service:processMessage(...)
        end
    )

    smart_event.timer(1, function()
            event.push("broadcast_timer")
        end, true
    )

    thread.current():suspend()
end

local function onExit()
    service:delete()
end

launch.launch(main, onExit)
