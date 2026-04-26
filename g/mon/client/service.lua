local service = {}

local component = require('component')
local loop = require('g.core.loop')
local ports = require('g.lib.net.ports')
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

  local dataLoop = loop.run('data', cfg['dataRefreshTime'] or 1.0, function()
    -- TODO(wind-eagle): handle error here
    local _
    obj.data, _ = client:request(cfg['serverAddress'], 'get', {'euAmount', 'euCapacity'}, 10.0)
  end)

  local drawLoop = loop.run('draw', cfg['screenRefreshTime'] or 1.0, function()
    graphics.draw(obj.gpu, obj.data)
  end)

  function obj:close()
    dataLoop:join()
    drawLoop:join()
  end

  return obj
end

return service
