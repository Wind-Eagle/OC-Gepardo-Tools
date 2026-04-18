local dns = {}

local config = require('g.core.config')
local uuids = require('g.core.uuids')
local addrs = require('g.lib.net.addrs')
local ports = require('g.lib.net.ports')

local defaultServerAddr = addrs.defaultPort(
  config.dnsAddr or '9a9ae872-15f8-44d8-a0e1-594678e13766',
  ports.dns)

function dns.serverAddr()
  local addr = defaultServerAddr
  local a, _ = addrs.unpack(addr)
  if not uuids.isUuid(a) then
    error('dns addr must be uuid')
  end
  return addr
end

function dns.resolver()
  local obj = {
    addr = dns.serverAddr()
  }

  function obj:lookup(client, name, timeout)
    checkArg(1, client, 'table')
    checkArg(2, name, 'string')
    checkArg(3, timeout, 'number')
    if uuids.isUuid(name) then return name, nil end
    local rsp, err = client:request(obj.addr, 'lookup', {name = name}, timeout)
    if err ~= nil then return nil, 'lookup: ' .. err end
    if rsp.addr == nil then return nil, 'lookup: not found' end
    return rsp.addr, nil
  end

  function obj:reverseLookup(client, addr, timeout)
    checkArg(1, client, 'table')
    checkArg(2, addr, 'string')
    checkArg(3, timeout, 'number')
    if not uuids.isUuid(addr) then
      error('address is not uuid')
    end
    local rsp, err = client:request(obj.addr, 'lookup', {addr = addr}, timeout)
    if err ~= nil then return nil, 'reverse lookup: ' .. err end
    if rsp.name == nil then return nil, 'reverse lookup: not found' end
    return rsp.name, nil
  end

  return obj
end

function dns.hello(client, name, timeout)
  checkArg(1, name, 'string')
  checkArg(2, timeout, 'number')
  local addr = dns.serverAddr()
  local rsp, err = client:request(addr, 'hello', {name = name}, timeout)
  if err ~= nil then return nil, 'hello: ' .. err end
  return rsp, nil
end

return dns
