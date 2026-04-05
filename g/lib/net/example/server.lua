local run = require('g.core.run')

run.main(function(...)
  local close = require('g.core.close')
  local relays = require('g.lib.net.relays')
  local rpc = require('g.lib.net.rpc')

  local relay = relays.router()
  close.defer(relay)
  rpc.serve(nil, relay, function(src, method, data)
    checkArg(1, src, 'string')
    checkArg(2, method, 'string')
    checkArg(3, data, 'table')
    local cb = ({
      isCatCute = function()
        local cat = data.cat
        if type(cat) ~= 'string' then return nil, 'cat name must be a string' end
        return {verdict = cat .. ' is a cute cat!'}, nil
      end,
    })[method]
    if cb == nil then error('unknown method: ' .. method) end
    return cb()
  end)
end, ...)
