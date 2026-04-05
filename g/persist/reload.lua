local reload = {}

local process = require('process')

local function startsWith(s, pre)
  return s:sub(1, #pre) == pre
end

local function persist(name)
  return not startsWith(name, 'g.') or startsWith(name, 'g.persist.')
end

local function cat2(a, b)
  local first = true
  local key = nil

  return function()
    local nk, nv
    if first then
      nk, nv = next(a, key)
      if nk ~= nil then
        key = nk
        return nk, nv
      end
      first = false
      key = nil
    end
    nk, nv = next(b, key)
    key = nk
    return nk, nv
  end
end

-- luacheck: globals package.__geReload
if not package.__geReload then
  local origLoaded = {}
  local mt = {}

  local function curLoaded()
    local info = process.info()
    if info == nil or info.data == nil or info.data.__geLoaded == nil then
      return nil
    end
    return info.data.__geLoaded
  end

  local function choose(key)
    if persist(key) then
      return origLoaded
    end
    return curLoaded() or origLoaded
  end

  function mt.__index(_, key)
    return choose(key)[key]
  end

  function mt.__newindex(_, key, val)
    choose(key)[key] = val
  end

  function mt.__pairs(_, ...)
    local cur = curLoaded()
    if cur == nil then
      return pairs(origLoaded)
    else
      return cat2(cur, origLoaded)
    end
  end

  package.__geReload = true
  for k, v in pairs(package.loaded) do
    origLoaded[k] = v
    package.loaded[k] = nil
  end
  setmetatable(package.loaded, mt)
end

function reload.enable()
  local data = process.info().data
  if data.__geLoaded == nil then
    data.__geLoaded = {}
  end
end

return reload
