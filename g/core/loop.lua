local loop = {}

local computer = require('computer')
local event = require('event')
local run = require('g.core.run')

function loop.run(name, interval, fn)
  checkArg(1, name, 'string')
  checkArg(2, interval, 'number')
  checkArg(3, fn, 'function')

  local obj = {}
  local done = false

  local t = run.thread(function()
    while not done do
      local now = computer.uptime()
      local next = now + interval
      local ok, err = pcall(fn)
      if not ok then
        print('loop ' .. name .. ' error: ' .. err)
      end
      while not done do
        local wait = next - computer.uptime()
        if wait <= 0 then break end
        local evt = event.pull(wait, 'g.core.loop.join')
        if evt == nil then break end
      end
    end
  end)

  function obj:join()
    done = true
    event.push('g.core.loop.join')
    t:join()
  end

  return obj
end

return loop
