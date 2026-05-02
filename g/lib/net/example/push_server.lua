local run = require('g.core.run')

run.main(function(...)
  local event = require('event')
  local close = require('g.core.close')
  local relays = require('g.lib.net.relays')
  local push = require('g.lib.net.push')

  local relay = relays.router()
  close.defer(relay)
  local srv = push.serve(nil, relay, function(src, method, data)
    checkArg(1, src, 'string')
    checkArg(2, method, 'string')
    checkArg(3, data, 'table')
    local cb = ({
      showCat = function()
        local cat = data.cat
        print('I see a cat named ' .. cat)
      end,
    })[method]
    if cb == nil then error('unknown method: ' .. method) end
    return cb()
  end)
  close.defer(srv)
  event.pull('interrupted')
end, ...)
