local relays = {}

local component = require('component')
local computer = require('computer')
local event = require('event')
local uuid = require('uuid')
local addrs = require('g.lib.net.addrs')
local ports = require('g.lib.net.ports')
local proto = require('g.lib.net.proto')
local Packet = require('g.lib.net.packet')

function relays.direct(modem)
  checkArg(1, modem, 'table', 'nil')

  if modem == nil then modem = component.modem end

  local obj = {}

  function obj:modem()
    return modem
  end

  function obj:send(packet, timeout)
    checkArg(1, packet, 'table')
    checkArg(2, timeout, 'number')
    local addr, port = addrs.unpack(packet.dst)
    if not modem.send(addr, port, packet:encode()) then
      return 'send error'
    end
    return nil
  end

  function obj:wait(port, filter, timeout)
    checkArg(1, port, 'number')
    checkArg(2, filter, 'function')
    checkArg(3, timeout, 'number')
    local deadline = computer.uptime() + timeout
    while true do
      local name, _, _, msgPort, _, rawMsg = event.pull(deadline - computer.uptime(), 'modem_message')
      if name == nil then return 'timed out' end
      if msgPort == port then
        local packet, err = Packet:decode(rawMsg)
        if err ~= nil then
          print('bad packet' .. err)
        else
          if filter(packet) then return nil end
        end
      end
    end
  end

  function obj:close() end

  return obj
end

function relays.router(modem)
  checkArg(1, modem, 'table', 'nil')

  if modem == nil then modem = component.modem end

  local obj = {
    id = uuid.next(),
    addr = modem.address,
    port = ports.router,
  }

  if not modem.open(obj.port) then
    error(string.format('cannot open port %d', obj.port))
  end

  local function handle(port, raw)
    if port ~= obj.port then return end
    local p, err = Packet:decode(raw)
    if err ~= nil then
      print('bad packet: ' .. err)
      return
    end
    if p.proto ~= proto.router then return end
    obj.routerAddr, obj.routerPort = addrs.unpack(p.src)
  end

  local function listener(_, _, _, port, _, raw)
    handle(port, raw)
  end

  event.listen('modem_message', listener)

  function obj:modem()
    return modem
  end

  function obj:waitAddr(timeout)
    checkArg(1, timeout, 'number')
    if obj.routerAddr ~= nil then return nil end
    local deadline = computer.uptime() + timeout
    while true do
      local name, _, _, _, port, _, raw = event.pull(deadline - computer.uptime(), 'modem_message')
      if name == nil then return 'timed out' end
      handle(port, raw)
      if obj.routerAddr ~= nil then return nil end
    end
  end

  function obj:close()
    event.ignore('modem_message', listener)
    modem.close(self.port)
  end

  function obj:send(packet, timeout)
    checkArg(1, packet, 'table')
    checkArg(2, timeout, 'number')
    local err = obj:waitAddr(timeout)
    if err ~= nil then return 'wait address: ' .. err end
    if not modem.send(obj.routerAddr, obj.routerPort, packet:encode()) then
      return 'send error'
    end
    return nil
  end

  function obj:wait(port, filter, timeout)
    checkArg(1, port, 'number')
    checkArg(2, filter, 'function')
    checkArg(3, timeout, 'number')
    local deadline = computer.uptime() + timeout
    while true do
      local name, _, _, msgPort, _, rawMsg = event.pull(deadline - computer.uptime(), 'modem_message')
      if name == nil then return 'timed out' end
      if msgPort == port then
        local packet, err = Packet:decode(rawMsg)
        if err ~= nil then
          print('bad packet: ' .. err)
        else
          if filter(packet) then return nil end
        end
      end
    end
  end

  return obj
end

return relays
