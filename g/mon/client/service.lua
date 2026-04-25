local service = {}

local component = require('component')
local event = require('event')
local ioutils = require('g.core.ioutils')
local serialization = require('serialization')
local ports = require('g.lib.net.ports')
local rpc = require('g.lib.net.rpc')
local run = require('g.core.run')
local graphics = require('g.mon.client.graphics')

local modem = component.modem

function service.new(cfg, relay, client)
  local obj = {
    cfg = cfg,
    data = {},
    gpu = nil,
    screenAddress = nil,
    addr = modem.address,
    port = ports.rpc,
  }

  obj.gpu = component.gpu
  obj.screenAddress = component.screen.address
  graphics.init(obj.gpu, obj.screenAddress)

  local dataTimer = event.timer(cfg['dataRefreshTime'] or 1.0, function()
    run.thread(function()
      local err
      obj.data, err = client:request(cfg['serverAddress'], 'get', {'euAmount', 'euCapacity'}, 10.0)
    end)
  end, math.huge)

  local drawTimer = event.timer(cfg['screenRefreshTime'] or 1.0, function()
    run.thread(function()
      graphics.draw(obj.gpu, obj.data)
    end)
  end, math.huge)

  function obj:close()
    event.cancel(dataTimer)
    event.cancel(drawTimer)
  end

  return obj
end

return service
