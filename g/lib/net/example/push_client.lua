local run = require('g.core.run')

run.main(function(...)
  local io = require('io')
  local shell = require('shell')
  local close = require('g.core.close')
  local dns = require('g.lib.net.dns')
  local relays = require('g.lib.net.relays')
  local rpc = require('g.lib.net.rpc')
  local push = require('g.lib.net.push')

  local _, options = shell.parse(...)
  local addr = options.addr
  if addr == nil then
    error('no server address specified')
  end

  local relay = relays.router()
  close.defer(relay)
  local resolv = dns.resolver()
  local rpc = rpc.Client:new(relay, resolv)
  close.defer(rpc)
  local client = push.Client:new(relay, resolv, rpc)
  close.defer(client)

  io.write('enter cat name: ')
  local cat = io.read('*line')
  local err = client:request(addr, 'showCat', {cat = cat}, 10.0)
  if err ~= nil then
    error('push error: ' .. err)
  end
end, ...)
