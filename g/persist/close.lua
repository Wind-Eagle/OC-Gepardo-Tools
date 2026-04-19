local close = {}

local process = require('process')
local string = require('string')

local procs = {}
local procCtr = 1

local function getState()
  local proc = process.findProcess()
  local data = proc.data
  if rawget(data, '__geClear') == nil then
    local state = {id = procCtr}
    procs[procCtr] = {
      inner = setmetatable({proc = proc}, {__mode='v'}),
      state = state,
    }
    procCtr = procCtr + 1
    data.__geClear = state
  end
  return rawget(data, '__geClear')
end

local function resetState(state)
  checkArg(1, state, 'table')
  local id = state.id
  local proc = procs[id].inner.proc
  procs[id] = nil
  if proc ~= nil then
    rawset(proc.data, '__geClear', nil)
  end
end

local function popScope(state, raiseErr)
  checkArg(1, state, 'table')
  checkArg(2, raiseErr, 'boolean')
  local last = state[#state]
  state[#state] = nil
  if #state == 0 then resetState(state) end
  local hadErrs = false
  for _, obj in ipairs(last) do
    local ok, err = xpcall(function() obj:close() end, function(err)
      return string.format('%s\n%s', err, debug.traceback())
    end)
    if not ok then
      print(string.format('error during cleanup: %s', err))
      hadErrs = true
    end
  end
  if raiseErr and hadErrs then
    error('there were some errors during cleanup!')
  end
end

function close.defer(obj)
  checkArg(1, obj, 'function', 'table')
  if type(obj) == 'table' then
    assert(type(obj.close) == 'function', 'object must have close() method')
  else
    local fn = obj
    obj = {close = function(_) fn() end}
  end
  local state = getState()
  if #state == 0 then
    error('cannot call defer() outside of any scope!')
  end
  local scope = state[#state]
  scope[#scope + 1] = obj
end

function close.scope(fn, backtrace)
  checkArg(1, fn, 'function')
  checkArg(2, backtrace, 'boolean', 'nil')
  local state = getState()
  state[#state + 1] = {}
  local ok, err = xpcall(fn, function(err)
    if not backtrace then return err end
    return string.format('%s\n%s', err, debug.traceback())
  end)
  popScope(state, ok)
  if not ok then
    error(string.format('caught error: %s', err))
  end
end

function close.gc()
  for key, proc in pairs(procs) do
    if proc.inner.proc == nil then
      local state = proc.state
      while #state ~= 0 do
        popScope(state, false)
      end
      assert(procs[key] == nil, 'must have been removed during last popScope()')
    end
  end
end

return close
