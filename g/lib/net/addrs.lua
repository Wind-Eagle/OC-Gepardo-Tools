local addrs = {}

local math = require('math')
local string = require('string')
local strs = require('g.core.strs')

function addrs.pack(addr, port)
  checkArg(1, addr, 'string')
  checkArg(2, port, 'number')
  return string.format('%s:%d', addr, port)
end

function addrs.unpack(src)
  checkArg(1, src, 'string')
  local pos = string.find(src, ':', 1, true)
  if pos == nil then
    error('port not found in address')
  end
  local addr = string.sub(src, 1, pos - 1)
  local port = math.tointeger(string.sub(src, pos + 1, -1))
  return addr, port
end

function addrs.defaultPort(addr, defaultPort)
  checkArg(1, addr, 'string')
  checkArg(2, defaultPort, 'number')
  if strs.contains(addr, ':') then return addr end
  return addrs.pack(addr, defaultPort)
end

return addrs
