local push = {}

local computer = require('computer')
local event = require('event')
local serialization = require('serialization')
local run = require('g.core.run')
local addrs = require('g.lib.net.addrs')
local Packet = require('g.lib.net.packet')
local ports = require('g.lib.net.ports')
local proto = require('g.lib.net.proto')

push.Client = {}

function push.Client:new(relay, resolv, rpc)
  checkArg(1, relay, 'table')
  checkArg(2, resolv, 'table', 'nil')
  if resolv == nil then
    checkArg(3, rpc, 'nil')
  else
    checkArg(3, rpc, 'table')
  end

  local obj = {}
  setmetatable(obj, self)
  self.__index = self

  local modem = relay:modem()
  local addr = modem.address

  function obj:close() end

  function obj:request(dst, method, data, timeout)
    checkArg(1, dst, 'string')
    checkArg(2, method, 'string')
    checkArg(4, timeout, 'number')
    local deadline = computer.uptime() + timeout
    dst = addrs.defaultPort(dst, ports.push)
    if resolv ~= nil then
      local err
      dst, err = resolv:lookupWithPort(rpc, dst, deadline - computer.uptime())
      if err ~= nil then return 'resolve: ' .. err end
    end
    local src = addrs.pack(addr, 0)
    local payload = serialization.serialize({method = method, data = data})
    local packet = Packet:new(proto.push, src, dst, payload)
    local err = relay:send(packet, deadline - computer.uptime())
    if err ~= nil then return 'send: ' .. err end
    return nil
  end

  return obj
end

function push.serve(port, relay, fn)
  checkArg(1, port, 'number', 'nil')
  checkArg(2, relay, 'table')
  checkArg(3, fn, 'function')

  if port == nil then port = ports.push end

  local obj = {}

  local modem = relay:modem()
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
        if packet.proto ~= proto.push then return end
        local data = serialization.unserialize(packet.data)
        fn(packet.src, data.method, data.data)
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

return push
