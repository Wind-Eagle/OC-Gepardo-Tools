local service = {}

local component = require('component')
local event = require('event')
local ioutils = require('g.core.ioutils')
local ports = require('g.lib.net.ports')
local rpc = require('g.lib.net.rpc')
local run = require('g.core.run')
local timeseries = require('g.mon.lib.timeseries')

local modem = component.modem

function service.new(cfg, relay, client)
  local obj = {
    cfg = cfg,
    tsData = {},
    addr = modem.address,
    port = ports.rpc,
  }

  local function loadData()
    local err
    obj.tsData, err = ioutils.readAndDecode(cfg['dataPath'])
    if err ~= nil then
      error('data read error: ' .. err)
    end
  end

  local function saveData()
    local err = ioutils.writeAndEncode(cfg['dataPath'], obj.tsData)
    if err ~= nil then
      error('data save error: ' .. err)
    end
  end

  loadData()

  local function serve(src, method, data)
    local cb = ({
        get = function()
          local res = {}
          for key, value in pairs(data) do
            res[key] = timeseries.tail(obj.tsData[value], cfg['getTailSize'] or 10)
          end
          return res, nil
        end,
        push = function()
          for _, point in pairs(data) do
            if obj.tsData[point['signal']] == nil then
              obj.tsData[point['signal']] = {}
            end
            timeseries.pushBack(obj.tsData[point['signal']], point['value'], point['timestamp'])
          end
          saveData()
          return {}, nil
        end
    })[method]
    if cb == nil then error('unknown method: ' .. method) end
    return cb()
  end

  local timer = event.timer(cfg['cleanupIntervalSeconds'] or 10.0, function()
    run.thread(function()
      for signal, _ in pairs(obj.tsData) do
        timeseries.trunc(obj.tsData[signal], cfg['storeTailSize'] or 10)
      end
      saveData()
    end)
  end, math.huge)

  local srv = rpc.serve(obj.port, relay, function(src, method, data)
    checkArg(1, src, 'string')
    checkArg(2, method, 'string')
    local ok, a, b = pcall(serve, src, method, data)
    if not ok then
      return nil, a
    end
    return a, b
  end)

  function obj:close()
    srv:close()
    event.cancel(timer)
  end

  return obj
end

return service
