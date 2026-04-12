local service = {}

local os = require('os')
local ioutils = require('g.core.ioutils')
local addrs = require('g.lib.net.addrs')
local ports = require('g.lib.net.ports')
local rpc = require('g.lib.net.rpc')

local function newDB()
  local obj = {}

  local data = {
    a2n = {},
    n2a = {},
  }

  function obj:lookup(name)
    checkArg(1, name, 'string')
    return data.n2a[name]
  end

  function obj:lookupAddr(addr)
    checkArg(1, addr, 'string')
    return data.a2n[addr]
  end

  function obj:bye(name)
    checkArg(1, name, 'string')
    local addr = data.n2a[name]
    if addr == nil then return end
    data.n2a[name] = nil
    data.a2n[addr] = nil
  end

  function obj:byeAddr(addr)
    checkArg(1, addr, 'string')
    local name = data.a2n[addr]
    if name == nil then return end
    data.n2a[name] = nil
    data.a2n[addr] = nil
  end

  function obj:hello(name, addr)
    checkArg(1, name, 'string')
    checkArg(2, addr, 'string')
    self:bye(name)
    self:byeAddr(addr)
    data.n2a[name] = addr
    data.a2n[addr] = name
  end

  function obj:reload(fname)
    checkArg(1, fname, 'string')
    local newData, err = ioutils.readAndDecode(fname)
    if err ~= nil then return 'read: ' .. err end
    data = newData
    return nil
  end

  function obj:commit(fname)
    checkArg(1, fname, 'string')
    local err = ioutils.writeAndEncode(fname .. '.new', data)
    if err ~= nil then return 'write: ' .. err end
    local ok, err = os.rename(fname .. '.new', fname)
    if not ok then return 'rename: ' .. err end
    return nil
  end

  return obj
end

function service.start(cfg, relay)
  checkArg(1, cfg, 'table')
  checkArg(2, relay, 'table')

  local port = cfg.port or ports.dns
  local fname = cfg.fname or '/var/dns.db'
  if type(port) ~= 'number' then error('port is not a number') end
  if type(fname) ~= 'string' then error('fname is not a string') end

  local db = newDB()
  local err = db:reload(fname)
  if err ~= nil then error(err) end

  local obj = {}

  local srv = rpc.serve(port, relay, function(src, method, data)
    checkArg(1, src, 'string')
    checkArg(2, method, 'string')
    local ok, res = pcall(function()
      local cb = ({
        lookup = function()
          local name, addr = data.name, data.addr
          if name == nil and addr == nil then error('no name and no addr') end
          if name ~= nil and addr ~= nil then error('there must be only one') end
          if name ~= nil then
            return { addr = db:lookup(name) }
          else
            return { name = db:lookupAddr(addr) }
          end
        end,
        hello = function()
          local name = data.name
          local addr, _ = addrs.unpack(src)
          if name == nil then error('no name') end
          db:hello(name, addr)
          local err = db:commit(fname)
          if err ~= nil then
            print('commit error: ' .. err)
          end
          return {}
        end,
        bye = function()
          local name, addr = data.name, data.addr
          if name == nil and addr == nil then error('no name and no addr') end
          if name ~= nil and addr ~= nil then error('there must be only one') end
          if name ~= nil then
            db:bye(name)
          else
            db:byeAddr(addr)
          end
          local err = db:commit(fname)
          if err ~= nil then
            print('commit error: ' .. err)
          end
          return {}
        end,
      })[method]
      if cb == nil then error('unknown method: ' .. method) end
      return cb()
    end)
    if not ok then return nil, 'failed: ' .. res end
    return res, nil
  end)

  function obj:close()
    srv:close()
  end

  return obj
end

return service
