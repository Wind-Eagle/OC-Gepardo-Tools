local serialization = require("serialization")

local random = require("util.random")

local message = {}

local function makePacket(address, port, srcAddress, srcPort, requestId, data)
    local packet = {
        requestId = requestId,
        address = address,
        port = port,
        srcAddress = srcAddress,
        srcPort = srcPort,
        data = data
    }
    return serialization.serialize(packet)
end

function message.makeRequestPacket(address, port, srcAddress, srcPort, data)
    local requestId = random.generateUid()
    return makePacket(address, port, srcAddress, srcPort, requestId, data), requestId
end

function message.makeResponsePacket(address, port, srcAddress, srcPort, requestId, data)
    return makePacket(address, port, srcAddress, srcPort, requestId, data)
end

function message.makeMessage(msg, requestType)
    msg["requestType"] = requestType
    return msg
end

function message.getRequestId(msg)
    return msg["requestId"]
end

function message.getAddress(msg)
    return msg["address"]
end

function message.getPort(msg)
    return msg["port"]
end

function message.getSrcAddress(msg)
    return msg["srcAddress"]
end

function message.getSrcPort(msg)
    return msg["srcPort"]
end

function message.patchAddressPort(msg, address, port)
    msg["address"] = address
    msg["port"] = port
end

function message.getData(msg)
    return msg["data"]
end

function message.getRequestType(msg)
    return msg["requestType"]
end

function message.parseMessage(msg)
    return serialization.unserialize(msg)
end

return message
