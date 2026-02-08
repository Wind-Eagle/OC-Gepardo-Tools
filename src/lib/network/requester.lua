local smart_require = require("util.smart_require")

local component = require("component")
local math = require("math")

local message = smart_require.reload("lib.network.message")
local NetworkRouter = smart_require.reload("lib.network.router")
local dns = smart_require.reload("lib.network.dns")
local network = smart_require.reload("lib.network.network")

local smart_event = smart_require.reload("util.smart_event")

local Future = smart_require.reload("lib.thread.future")

local Requester = {}

function Requester:delete()
    if self.modem then
        self.modem.close(self.port)
        self.modem.close(network.network_broadcast_port)
    end
end

function Requester:new(port, callback)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    obj.port = port
    obj.callback = callback

    if not component.isAvailable("modem") then
        error("Network card (modem) is not available")
    end

    if port == network.network_broadcast_port then
        error("This port is reserved for network internal communication")
    end

    obj.modem = component.modem
    
    if obj.modem.isOpen(port) then
        error("Port is already being listened")
    end

    if obj.modem.isOpen(network.network_broadcast_port) then
        error("Network system port is already being listened")
    end

    obj.requestTable = {}
    obj.router = NetworkRouter:new()
    obj.routerReady = Future:new()

    return obj
end

function Requester:start()
    self.modem.open(self.port)
    self.modem.open(network.network_broadcast_port)

    smart_event.listen("modem_message", function(...)
            self:_processMessage(...)
        end
    )
    self:waitUntilReady()
end

function Requester:_sendPacket(packet)
    local pointAddress, pointPort = self.router:getNearestPoint()
    self.modem.send(pointAddress, pointPort, packet)
end

function Requester:_processMessage(_, _, _, port, _, rawMessage)
    local msg = message.parseMessage(rawMessage)
    if port == network.network_broadcast_port and message.getRequestType(message.getData(msg)) == network.network_identification_message_type then
        self.router:setNearestPoint(message.getAddress(msg), math.tointeger(message.getPort(msg)))
        self.routerReady:set(true)
        return
    end
    local promise = self.requestTable[message.getRequestId(msg)]
    if promise == nil then
        local data = message.getData(msg)
        local address = message.getAddress(msg)
        local port = message.getPort(msg)
        local srcAddress = message.getSrcAddress(msg)
        local srcPort = message.getSrcPort(msg)
        local requestId = message.getRequestId(msg)
        self.callback(data, address, port, srcAddress, srcPort, requestId)
        return
    end
    promise:set(msg)
end

function Requester:waitUntilReady()
    return self.routerReady:get()
end

function Requester:sendRequest(address, port, data)
    local packet, requestId = message.makeRequestPacket(address, port, self.modem.address, self.port, data)

    local promise = Future:new()
    self.requestTable[requestId] = promise

    self:_sendPacket(packet)
    return promise
end

function Requester:sendResponse(address, port, requestId, data)
    local packet = message.makeResponsePacket(address, port, self.modem.address, self.port, requestId, data)
    self:_sendPacket(packet)
end

function Requester:getDNSName(address)
    local waitForResponse = self:sendRequest(dns.dns_server_address, dns.dns_server_port, dns.makeDNSAskMessage(address))
    local result = waitForResponse:get()
    return result[address]
end

return Requester
