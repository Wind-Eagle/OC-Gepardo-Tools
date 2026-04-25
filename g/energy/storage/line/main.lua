local run = require('g.core.run')

run.main(function(...)
  local event = require('event')
  local shell = require('shell')
  local close = require('g.core.close')
  local relays = require('g.lib.net.relays')
  local ioutils = require('g.core.ioutils')
  local dns = require('g.lib.net.dns')
  local rpc = require('g.lib.net.rpc')
  local push = require('g.lib.net.push')
  local service = require('g.energy.storage.line.service')

  local _, options = shell.parse(...)
  if options.help then
    print('energy controller service')
    print('usage: ./main.lua --config=<config file>')
    return
  end
  if options.config == nil then
    error('no config file provided!')
  end
  local cfg, err = ioutils.readAndDecode(options.config)
  if err ~= nil then
    error('config read error: ' .. err)
  end

  local relay = relays.direct()
  close.defer(relay)
  local resolv = dns.resolver()
  local client = rpc.Client:new(relay, resolv)
  close.defer(client)
  local pushClient = push.Client:new(relay, resolv, client)
  close.defer(pushClient)
  local svc = service.new(cfg, relay, pushClient)
  close.defer(svc)
  event.pull('interrupted')
end, ...)
