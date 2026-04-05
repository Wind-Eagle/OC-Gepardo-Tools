local run = {}

local reload = require('g.core.reload')
reload.enable()

local close = require('g.core.close')
local thread = require('thread')

local function _thread(fn, backtrace, ...)
  checkArg(1, fn, 'function')
  checkArg(2, backtrace, 'boolean', 'nil')
  return thread.create(function(args)
    close.scope(function()
      fn(table.unpack(args, 1, args.n))
    end, backtrace)
  end, table.pack(...))
end

function run.thread(fn, ...)
  checkArg(1, fn, 'function')
  return _thread(fn, true, ...)
end

function run.main(fn, ...)
  checkArg(1, fn, 'function')
  local args = table.pack(...)
  close.scope(function()
    local ok, err = false, 'thread not finished'
    local t = _thread(function()
      ok, err = xpcall(function()
        fn(table.unpack(args, 1, args.n))
      end, function(err)
        return string.format('%s\n%s', err, debug.traceback())
      end)
    end, false)
    close.defer(function()
      if t ~= nil then
        t:kill()
      end
    end)
    t:join()
    t = nil
    if not ok then
      error(err)
    end
  end)
end

return run
