local run = require('g.core.run')

run.main(function(...)
  local shell = require('shell')
  local close = require('g.core.close')
  local ioutils = require('g.core.ioutils')
  local relays = require('g.lib.net.relays')
  local service = require('g.infra.dns.service')

  local _, options = shell.parse(...)
  if options.help then
    print('dns service')
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
  local relay = relays.router()
  close.defer(relay)
  service.serve(cfg, relay)
end, ...)
