local Packet = {}

local string = require('string')
local uuids = require('g.core.uuids')
local addrs = require('g.lib.net.addrs')

local packetVersion = 0
local minHeaderLen = 79

function Packet:headerLen()
  return 79
end

function Packet:new(proto, src, dst, data)
  checkArg(1, proto, 'number')
  checkArg(2, src, 'string')
  checkArg(3, dst, 'string')
  checkArg(4, data, 'string')

  local obj = {proto = proto, src = src, dst = dst, data = data}
  setmetatable(obj, self)
  self.__index = self
  return obj
end

local function encodeAddr(addr)
  local a, p = addrs.unpack(addr)
  if not uuids.isUuid(a) then
    error('address is not uuid')
  end
  return a .. string.char(p%256, p//256)
end

local function decodeAddr(raw)
  if #raw ~= 38 then
    return nil, 'bad raw address'
  end
  local addr = raw:sub(1, 36)
  local port = raw:byte(37) + 256*raw:byte(38)
  if not uuids.isUuid(addr) then
    return nil, 'address is not uuid'
  end
  return addrs.pack(addr, port), nil
end

function Packet:encode()
  return string.char(packetVersion, self:headerLen(), self.proto) ..
    encodeAddr(self.src) .. encodeAddr(self.dst) .. self.data
end

function Packet:decode(raw)
  checkArg(1, raw, 'string')
  if #raw < minHeaderLen then return nil, 'packet is too small' end
  local version = raw:byte(1)
  local _ = version
  local headerLen = raw:byte(2)
  if headerLen < minHeaderLen then return nil, 'header length is too small' end
  if #raw < headerLen then return nil, 'packet is too small' end
  local proto = raw:byte(3)
  local src, err = decodeAddr(raw:sub(4, 41))
  if err ~= nil then return nil, 'bad src: ' .. err end
  local dst, err = decodeAddr(raw:sub(42, 79))
  if err ~= nil then return nil, 'bad dst: ' .. err end
  return Packet:new(proto, src, dst, raw:sub(headerLen + 1)), nil
end

return Packet
