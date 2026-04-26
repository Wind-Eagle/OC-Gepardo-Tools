local service = {}

local component = require('component')
local event = require('event')
local ports = require('g.lib.net.ports')
local run = require('g.core.run')

local modem = component.modem

function service.new(cfg, relay, pushClient)
  local obj = {
    cfg = {},
    addr = modem.address,
    port = ports.rpc,
  }

  local function getStorageItems()
    local storages = {}
    for _, element in ipairs({"batbox", "cesu", "mfe", "mfsu"}) do
      for k, v in component.list("ic2_te_" .. element) do
        storages[k] = v
      end
      for k, v in component.list("ic2_te_chargepad_" .. element) do
        storages[k] = v
      end
    end
    return storages
  end

  local function getLineInfo()
    local sumEnergy = 0
    local sumCapacity = 0
    local items = getStorageItems()
    for item, _ in pairs(items) do
      sumEnergy = sumEnergy + component.proxy(item).getEnergy()
      sumCapacity = sumCapacity + component.proxy(item).getCapacity()
    end
    return sumEnergy, sumCapacity
  end

  local timer = event.timer(cfg['broadcastIntervalSeconds'], function()
    run.thread(function()
      local sumEnergy, sumCapacity = getLineInfo()
      pushClient:request(
        cfg['energyControllerAddress'], 'energyData',
        {euAmount = sumEnergy, euCapacity = sumCapacity, lineNumber = cfg['lineNumber']},
        10.0)
    end)
  end, math.huge)


  function obj:close()
    event.cancel(timer)
  end

  return obj
end

return service
