local run = require('g.core.run')

run.main(function(...)
  local io = require('io')
  local shell = require('shell')
  local close = require('g.core.close')
  local addrs = require('g.lib.net.addrs')
  local dns = require('g.lib.net.dns')
  local ports = require('g.lib.net.ports')
  local relays = require('g.lib.net.relays')
  local rpc = require('g.lib.net.rpc')

  local _, options = shell.parse(...)
  local addr = options.addr
  if addr == nil then
    error('no server address specified')
  end
  addr = addrs.defaultPort(addr, ports.rpc)

  local relay = relays.router()
  close.defer(relay)
  local resolv = dns.resolver()
  local client = rpc.Client:new(relay, resolv)
  close.defer(client)

  io.write('enter cat name: ')
  local cat = io.read('*line')
  local res, err = client:request(addr, 'isCatCute', {cat = cat}, 10.0)
  if err ~= nil then
    error('rpc error: ' .. err)
  end
  print('verdict: ' .. res.verdict)
end, ...)
