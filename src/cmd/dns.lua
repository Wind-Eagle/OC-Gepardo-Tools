local smart_require = require("util.smart_require")

local Requester = smart_require.reload("lib.network.requester")

local network = smart_require.reload("lib.network.network")
local dns = smart_require.reload("lib.network.dns")

local launch = smart_require.reload("util.launch")

local component = require("component")
local shell = require("shell")

local function help()
    print("=" .. string.rep("=", 40))
    print("DNS registrator")
    print("=" .. string.rep("=", 40))
    print("Usage: ./dns.lua --name=<name>")
end

local name = nil
local _, options = shell.parse(...)

for argKey, argValue in pairs(options) do
    if not argValue then break end

    if argKey == "help" then
        help()
        os.exit(0)
    elseif argKey == "name" then
        name = argValue
    end
end

if not name then
    print("ERROR: DNS name is required!")
    print()
    help()
    os.exit(1)
end

local requester = nil

local function main()
    local address = component.modem.address

    requester = Requester:new(8000)
    requester:start()
    local promise = requester:sendRequest(dns.dns_server_address, dns.dns_server_port, dns.makeDNSRegistraionMessage(address, name))
    local result = promise:get()
    if network.isNetworkErrorMessage(result) then
        error("DNS service cannot be reached: " .. network.getNetworkErrorDetails(result))
    end
    print("DNS registered successfully")
end

local function onExit()
    if requester then
        requester:delete()
    end
end

launch.launch(main, onExit)
