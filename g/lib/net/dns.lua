local dns = {}

local computer = require('computer')
local config = require('g.core.config')
local uuids = require('g.core.uuids')
local addrs = require('g.lib.net.addrs')
local hosts = require('g.lib.net.hosts')
local ports = require('g.lib.net.ports')

local defaultServerAddr = addrs.defaultPort(
  config.dnsAddr or hosts['dns'],
  ports.dns)

function dns.serverAddr()
  local addr = defaultServerAddr
  local a, _ = addrs.unpack(addr)
  if not uuids.isUuid(a) then
    error('dns addr must be uuid')
  end
  return addr
end

local function newCache(ttl)
  checkArg(1, ttl, 'number')

  local obj = {}

  local data = {}

  function obj:put(now, key, val)
    checkArg(1, now, 'number')
    data[key] = {val, now + ttl}
  end

  function obj:get(now, key)
    checkArg(1, now, 'number')
    local e = data[key]
    if e == nil then return nil end
    local val, exp = e[1], e[2]
    if exp < now then
      data[key] = nil
      return nil
    end
    return val
  end

  return obj
end

function dns.resolver(cfg)
  checkArg(1, cfg, 'table', 'nil')

  if cfg == nil then cfg = {} end
  local ttl = cfg.ttl or 120 -- ttl is in seconds

  local obj = {
    addr = dns.serverAddr()
  }

  local cache = newCache(ttl)
  local rcache = newCache(ttl)

  function obj:lookup(client, name, timeout)
    checkArg(1, client, 'table')
    checkArg(2, name, 'string')
    checkArg(3, timeout, 'number')
    if uuids.isUuid(name) then return name, nil end
    local val = hosts[name]
    if val ~= nil then return val, nil end
    val = cache:get(computer.uptime(), name)
    if val ~= nil then return val, nil end
    local rsp, err = client:request(obj.addr, 'lookup', {name = name}, timeout)
    if err ~= nil then return nil, 'lookup: ' .. err end
    if rsp.addr == nil then return nil, 'lookup: not found' end
    cache:put(computer.uptime(), name, rsp.addr)
    return rsp.addr, nil
  end

  function obj:lookupWithPort(client, full, timeout)
    checkArg(1, client, 'table')
    checkArg(2, full, 'string')
    checkArg(3, timeout, 'number')
    local name, port = addrs.unpack(full)
    local res, err = obj:lookup(client, name, timeout)
    if err ~= nil then return nil, err end
    return addrs.pack(res, port)
  end

  function obj:reverseLookup(client, addr, timeout)
    checkArg(1, client, 'table')
    checkArg(2, addr, 'string')
    checkArg(3, timeout, 'number')
    if not uuids.isUuid(addr) then
      error('address is not uuid')
    end
    local val = rcache:get(computer.uptime(), addr)
    if val ~= nil then return val, nil end
    local rsp, err = client:request(obj.addr, 'lookup', {addr = addr}, timeout)
    if err ~= nil then return nil, 'reverse lookup: ' .. err end
    if rsp.name == nil then return nil, 'reverse lookup: not found' end
    rcache:put(computer.uptime(), addr, rsp.name)
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
