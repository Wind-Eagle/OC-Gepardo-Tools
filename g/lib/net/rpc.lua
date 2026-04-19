local rpc = {}

local computer = require('computer')
local event = require('event')
local math = require('math')
local serialization = require('serialization')
local uuid = require('uuid')
local run = require('g.core.run')
local addrs = require('g.lib.net.addrs')
local Packet = require('g.lib.net.packet')
local proto = require('g.lib.net.proto')
local misc = require('g.lib.net.misc')
local ports = require('g.lib.net.ports')

rpc.Client = {}

function rpc.Client:new(relay, resolv)
  checkArg(1, relay, 'table')
  checkArg(2, resolv, 'table', 'nil')

  local obj = {}
  setmetatable(obj, self)
  self.__index = self

  local modem = relay:modem()
  local addr = modem.address
  local port = misc.pickPort(modem, 32768)
  if port == nil then
    error('could not pick port, there are none left')
  end

  function obj:close()
    modem.close(port)
  end

  function obj:request(dst, method, data, timeout)
    checkArg(1, dst, 'string')
    checkArg(2, method, 'string')
    checkArg(4, timeout, 'number')
    local deadline = computer.uptime() + timeout
    dst = addrs.defaultPort(dst, ports.rpc)
    if resolv ~= nil then
      local err
      dst, err = resolv:lookupWithPort(obj, dst, deadline - computer.uptime())
      if err ~= nil then return nil, 'resolve: ' .. err end
    end
    local id = uuid.next()
    local src = addrs.pack(addr, port)
    local payload = serialization.serialize({id = id, method = method, data = data})
    local packet = Packet:new(proto.rpc, src, dst, payload)
    local err = relay:send(packet, deadline - computer.uptime())
    if err ~= nil then return nil, 'send: ' .. err end
    local rsp
    local err = relay:wait(port, function(rspPacket)
      if rspPacket.proto ~= proto.rpc then return false end
      local ok, res = pcall(function() return serialization.unserialize(rspPacket.data) end)
      if not ok then
        print('bad packet: ' .. res)
        return false
      end
      if res.id ~= id then return false end
      rsp = res
      return true
    end, deadline - computer.uptime())
    if err ~= nil then return nil, 'wait: ' .. err end
    if err ~= nil then return nil, 'wait for response: ' .. err end
    if rsp.err ~= nil then return nil, rsp.err end
    return rsp.data, nil
  end

  obj.port = port
  return obj
end

function rpc.serve(port, relay, fn)
  checkArg(1, port, 'number', 'nil')
  checkArg(2, relay, 'table')
  checkArg(3, fn, 'function')

  if port == nil then port = ports.rpc end

  local obj = {}

  local modem = relay:modem()
  local addr = modem.address
  if not modem.open(port) then
    error(string.format('cannot open port %d', port))
  end

  local function cb(_, _, _, msgPort, _, rawMsg)
    if msgPort ~= port then return end
    run.thread(function()
      local ok, err = xpcall(function()
        local packet, err = Packet:decode(rawMsg)
        if err ~= nil then
          print('bad packet: ' .. err)
          return
        end
        if packet.proto ~= proto.rpc then return end
        local data = serialization.unserialize(packet.data)
        local res, err = fn(packet.src, data.method, data.data)
        local payload = {id = data.id}
        if err == nil then
          payload.data = res
        else
          payload.err = err
        end
        local rspData = serialization.serialize(payload)
        local err = relay:send(Packet:new(proto.rpc, addrs.pack(addr, port), packet.src, rspData), math.huge)
        if err ~= nil then
          print('could not send response to addr ' .. packet.src .. ': ' .. err '!')
        end
      end, function(err)
        return string.format('%s\n%s', err, debug.traceback())
      end)
      if not ok then
        print('error handling request: ' .. err)
      end
    end)
  end

  event.listen('modem_message', cb)

  function obj:close()
    event.ignore('modem_message', cb)
    modem.close(port)
  end

  return obj
end

return rpc
