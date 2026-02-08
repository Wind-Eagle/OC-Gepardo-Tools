local network = {}

local smart_require = require("util.smart_require")

local message = smart_require.reload("lib.network.message")

network.network_identification_message_type = "network_msg_id"
network.network_error_message_type = "network_error_id"
network.network_internal_port = 80
network.network_broadcast_port = 443

function network.makeNetworkIdentificationMessage(address, port)
    local data = {
        address = address,
        port = port,
        data = {
            requestType = network.network_identification_message_type
        },
    }
    return data
end

function network.makeNetworkErrorMessage(errorDetails)
    local data = {
        data = {
            requestType = network.network_error_message_type
        },
        errorDetails = errorDetails
    }
    return data
end

function network.isNetworkErrorMessage(msg)
    return message.getRequestType(msg) == network.network_error_message_type
end

function network.getNetworkErrorDetails(msg)
    if message.isNetworkErrorMessage(msg) then
        return message.getData(msg)["errorDetails"]
    end
    return nil
end

return network
