local service = {}

local component = require('component')
local event = require('event')
local math = require('math')
local addrs = require('g.lib.net.addrs')
local ports = require('g.lib.net.ports')
local proto = require('g.lib.net.proto')
local Packet = require('g.lib.net.packet')

local modem = component.modem

function service.new(cfg)
  checkArg(1, cfg, 'table')

  local obj = {
    cfg = cfg,
    addr = modem.address,
    port = ports.router,
  }

  if not modem.open(obj.port) then
    error(string.format('cannot open port %d', obj.port))
  end

  local timer = event.timer(cfg.broadcastInterval or 1.0, function()
    local addr = addrs.pack(obj.addr, obj.port)
    local packet = Packet:new(proto.router, addr, addr, '')
    modem.broadcast(obj.port, packet:encode())
  end, math.huge)

  local function listener(_, _, _, port, _, raw)
    if port ~= obj.port then return end
    local p, err = Packet:decode(raw)
    if err ~= nil then
      print('broken packet: ' .. err)
      return
    end
    if p.proto == proto.router then return end
    local dAddr, dPort = addrs.unpack(p.dst)
    modem.send(dAddr, dPort, raw)
  end

  event.listen('modem_message', listener)

  function obj:close()
    modem.close(obj.port)
    event.cancel(timer)
    event.ignore('modem_message', listener)
  end

  return obj
end

return service
