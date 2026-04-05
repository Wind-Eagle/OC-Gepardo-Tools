local run = require('g.core.run')

run.main(function(...)
  local event = require('event')
  local shell = require('shell')
  local close = require('g.core.close')
  local ioutils = require('g.core.ioutils')
  local service = require('g.infra.router.service')

  local _, options = shell.parse(...)
  if options.help then
    print('router service')
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
  local svc = service.new(cfg)
  close.defer(svc)
  event.pull('interrupted')
end, ...)
