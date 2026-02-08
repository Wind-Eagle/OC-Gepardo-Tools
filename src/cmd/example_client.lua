local smart_require = require("util.smart_require")

local Requester = smart_require.reload("lib.network.requester")
local dns = smart_require.reload("lib.network.dns")
local message = smart_require.reload("lib.network.message")

local launch = smart_require.reload("util.launch")

local shell = require("shell")

local function help()
    print("=" .. string.rep("=", 40))
    print("Cat cuteness checker")
    print("=" .. string.rep("=", 40))
    print("Usage: ./example_client.lua --name=<name> --server_address=<server address>")
end

local name = nil
local serverAddress = nil
local _, options = shell.parse(...)

for argKey, argValue in pairs(options) do
    if not argValue then break end

    if argKey == "help" then
        help()
        os.exit(0)
    elseif argKey == "name" then
        name = argValue
    elseif argKey == "server_address" then
        serverAddress = argValue
    end
end

if not name then
    print("ERROR: cat name is required!")
    print()
    help()
    os.exit(1)
end

if not serverAddress then
    print("ERROR: server address is required!")
    print()
    help()
    os.exit(1)
end

local requester = nil

local function main()
    requester = Requester:new(8000)
    requester:start()

    local promise = requester:sendRequest(dns.dns_server_address, dns.dns_server_port, dns.makeDNSAskMessage({serverAddress}))
    local addressNameTable = dns.getAddressNameTable(promise:get())
    local address = addressNameTable[serverAddress]

    local promise = requester:sendRequest(address, 80, {catName = name, requestType = "is_cat_cute"})
    local result = promise:get()
    local msg = message.getData(result)
    print(msg["isCatCute"])
end

local function onExit()
    if requester then
        requester:delete()
    end
end

launch.launch(main, onExit)
