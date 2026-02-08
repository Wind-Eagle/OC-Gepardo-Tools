local NetctlService = {}

local smart_require = require("util.smart_require")

local message = smart_require.reload("lib.network.message")
local network = smart_require.reload("lib.network.network")

local serialization = require("serialization")
local component = require("component")

function NetctlService:delete()
    self.modem.close(self.port)
    self.modem.close(network.network_broadcast_port)
end

function NetctlService:new(neighbours, port)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    if not component.isAvailable("modem") then
        error("Network card (modem) is not available")
    end

    obj.modem = component.modem

    if obj.modem.isOpen(port) then
        error("Port is already being listened")
    end

    if obj.modem.isOpen(network.network_broadcast_port) then
        error("Network system port is already being listened")
    end

    obj.neighbours = neighbours
    obj.port = port
    obj.modem.open(obj.port)
    obj.modem.open(network.network_broadcast_port)

    return obj
end

function NetctlService:broadcastAddress()
    local message = serialization.serialize(network.makeNetworkIdentificationMessage(self.modem.address, network.network_internal_port))
    self.modem.broadcast(network.network_broadcast_port, message)
end

function NetctlService:processMessage(_, _, _, _, _, rawMessage)
    local msg = message.parseMessage(rawMessage)
    if message.getRequestType(message.getData(msg)) == network.network_identification_message_type then
        return
    end
    local dstAddress = message.getAddress(msg)
    local dstPort = message.getPort(msg)
    local srcAddress = message.getSrcAddress(msg)
    local srcPort = message.getSrcPort(msg)

    message.patchAddressPort(msg, msg["originalAddress"], msg["originalPort"])
    local success = self.modem.send(dstAddress, dstPort, serialization.serialize(msg))
    message.patchAddressPort(msg, dstAddress, dstPort)

    -- TODO: rework connection errors
    if success == false then
        -- TODO: send to neighbours in parallel
        local neighbourSendStatus = false
        for neighbourAddress, neighbourPort in pairs(self.neighbours) do
            if not (neighbourAddress == srcAddress and neighbourPort == srcPort) then
                local success = self.modem.send(neighbourAddress, neighbourPort, serialization.serialize(msg))
                if success then
                    neighbourSendStatus = true
                    break
                end
            end
        end
        if neighbourSendStatus == false then
            self.modem.send(srcAddress, srcPort,
                            message.makeResponseRequest(
                                        srcAddress, srcPort, message.getRequestId(msg),
                                        network.makeNetworkErrorMessage("connection failed")
                                    )
                            )
        end
    end
end

return NetctlService
