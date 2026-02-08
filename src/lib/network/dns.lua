local dns = {}

local smart_require = require("util.smart_require")

local message = smart_require.reload("lib.network.message")

dns.dns_registration_message_type = "dns_registration_msg"
dns.dns_ask_message_type = "dns_ask_msg"
dns.dns_remove_message_type = "dns_remove_msg"
dns.dns_response_message_type = "dns_response_msg"
dns.dns_error_message_type = "dns_error_msg"

-- dns.dns_server_address = "01c292a5-deb9-4850-a99b-ffa23ae6ff12"
dns.dns_server_address = "3bb64914-d0d3-4d81-b844-8569674c5b03" 
dns.dns_server_port = 80

function dns.makeDNSRegistraionMessage(address, name)
    local message = {
        address = address,
        name = name,
        requestType = dns.dns_registration_message_type
    }
    return message
end

function dns.makeDNSAskMessage(nameList)
    local message = {
        nameList = nameList,
        requestType = dns.dns_ask_message_type
    }
    return message
end

function dns.makeDNSRemoveMessage(address)
    local message = {
        address = address,
        requestType = dns.dns_remove_message_type
    }
    return message
end

function dns.makeDNSResponseMessage(data)
    local message = {
        addressNameTable = data,
        requestType = dns.dns_response_message_type
    }
    return message
end

function dns.makeDNSErrorMessage(errorDetails)
    local message = {
        requestType = dns.dns_error_message_type,
        errorDetails = errorDetails
    }
    return message
end

function dns.getAddressNameTable(responseMessage)
    return message.getData(responseMessage)["addressNameTable"]
end

return dns
