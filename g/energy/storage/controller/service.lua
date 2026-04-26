local service = {}

local component = require('component')
local computer = require('computer')
local loop = require('g.core.loop')
local times = require('g.core.times')
local ports = require('g.lib.net.ports')
local push = require('g.lib.net.push')

local modem = component.modem

function service.new(cfg, relay, client)
  local obj = {
    cfg = cfg,
    euAmount = {},
    euCapacity = {},
    addr = modem.address,
    port = ports.push,
  }

  local linesCnt = #cfg['lines']

  local function getLinesInfo()
    local sumEnergy = 0
    local sumCapacity = 0
    local minEnergyLine = nil
    for index = 1, linesCnt do
      local euAmount = obj.euAmount[cfg['lines'][index]['lineNumber']]
      local euCapacity = obj.euCapacity[cfg['lines'][index]['lineNumber']]
      if euAmount ~= nil then
        sumEnergy = sumEnergy + euAmount
        sumCapacity = sumCapacity + euCapacity
        if minEnergyLine == nil or euAmount < obj.euAmount[cfg['lines'][minEnergyLine]['lineNumber']] then
          minEnergyLine = index
        end
      end
    end

    if minEnergyLine == nil then
      minEnergyLine = 1
    end
    return sumEnergy, sumCapacity, minEnergyLine
  end

  local function sendToMon(sumEnergy, sumCapacity)
    local _, err = client:request(cfg['monAddress'], 'push', {
      {signal = 'euAmount', value = sumEnergy, timestamp = times.ticksFromEpoch()},
      {signal = 'euCapacity', value = sumCapacity, timestamp = times.ticksFromEpoch()},
    }, 2.0)
    if err ~= nil then
      error('mon error: ' .. err)
    end
  end

  local lastRedstoneUpdate = computer.uptime()

  local function changeRedstone(minEnergyLine)
    local curTime = computer.uptime()
    if curTime - lastRedstoneUpdate < 15.0 then
      return
    end
    lastRedstoneUpdate = curTime
    for index = 1, linesCnt do
      component.proxy(cfg['lines'][index]['redstone']).setOutput(1, 0)
    end
    component.proxy(cfg['lines'][minEnergyLine]['redstone']).setOutput(1, 15)
  end

  local lp = loop.run('main', 1.0, function()
    local sumEnergy, sumCapacity, minEnergyLine = getLinesInfo()
    sendToMon(sumEnergy, sumCapacity)
    changeRedstone(minEnergyLine)
  end)

  local srv = push.serve(obj.port, relay, function(src, method, data)
    checkArg(1, src, 'string')
    checkArg(2, method, 'string')
    if method == 'energyData' then
      obj.euAmount[data['lineNumber']] = data['euAmount']
      obj.euCapacity[data['lineNumber']] = data['euCapacity']
    end
  end)

  function obj:close()
    lp:join()
    srv:close()
  end

  return obj
end

return service
