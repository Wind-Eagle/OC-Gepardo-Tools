local run = require('g.core.run')

run.main(function(...)
  local shell = require('shell')
  local close = require('g.core.close')
  local dns = require('g.lib.net.dns')
  local relays = require('g.lib.net.relays')
  local rpc = require('g.lib.net.rpc')

  local _, options = shell.parse(...)
  if options.help then
    print('register dns name')
    print('usage: ./main.lua --name=<name>')
    return
  end
  if options.name == nil then
    error('name is not specified')
  end
  local relay = relays.router()
  close.defer(relay)
  local client = rpc.Client:new(relay, nil)
  close.defer(client)
  local _, err = dns.hello(client, options.name, 5.0)
  if err ~= nil then
    error('hello error: ' .. err)
  end
  print('done.')
end, ...)
