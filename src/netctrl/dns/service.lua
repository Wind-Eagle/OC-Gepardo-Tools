local DNSService = {}

local smart_require = require("util.smart_require")

local DNSStorage = smart_require.reload("netctrl.dns.storage")
local dns = smart_require.reload("lib.network.dns")
local message = smart_require.reload("lib.network.message")
local Requester = smart_require.reload("lib.network.requester")

local component = require("component")
local thread = require("thread")

function DNSService:serve(data, _, _, srcAddress, srcPort, requestId)
    local response = nil
    if message.getRequestType(data) == dns.dns_registration_message_type then
        local address = data["address"]
        local name = data["name"]
        local success = self.storage:set(address, name)
        if success then
            print("Processed registration message")
            response = dns.makeDNSResponseMessage({})
        else
            print("Error in processing registration message")
            response = dns.makeDNSErrorMessage("Cannot register DNS name")
        end
    elseif message.getRequestType(data) == dns.dns_ask_message_type then
        local nameList = data["nameList"]
        local result = {}
        print("Processing ask message:")
        for _, name in pairs(nameList) do
            local address = self.storage:getByName(name)
            result[name] = address
            print(address, name)
        end
        response = dns.makeDNSResponseMessage(result)
    elseif message.getRequestType(data) == dns.dns_remove_message_type then
        local address = data["address"]
        local success = self.storage:delete(address)
        if success then
            print("Processed remove message:")
            print(address)
            response = dns.makeDNSResponseMessage({})
        else 
            print("Error in processing remove message:")
            response = dns.makeDNSErrorMessage("Cannot remove DNS name")
        end
    end
    self.requester:sendResponse(srcAddress, srcPort, requestId, response)
end

function DNSService:delete()
    self.requester:delete()
end

function DNSService:new(dataPath)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    if not component.isAvailable("modem") then
        error("Network card (modem) is not available")
    end

    self.dataPath = dataPath

    return obj
end

function DNSService:start()
    self.storage = DNSStorage:new(self.dataPath)
    self.requester = Requester:new(dns.dns_server_port, function(...)
            self:serve(...)
        end
    )
    self.requester:start()

    thread.current():suspend()
end

return DNSService
