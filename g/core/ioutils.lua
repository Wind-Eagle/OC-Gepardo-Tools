local ioutils = {}

local io = require('io')
local serialization = require('serialization')

function ioutils.readAndDecode(fname)
  checkArg(1, fname, 'string')
  local f, err = io.open(fname, 'r')
  if f == nil then return nil, err end
  local res
  local ok, err = pcall(function()
    local data = f:read('*all')
    res = serialization.unserialize(data)
  end)
  f:close()
  if not ok then return nil, err end
  return res, nil
end

function ioutils.writeAndEncode(fname, data)
  checkArg(1, fname, 'string')
  local f, err = io.open(fname, 'w')
  if f == nil then return err end
  local ok, err = pcall(function()
    f:write(serialization.serialize(data))
  end)
  f:close()
  if not ok then return err end
  return nil
end

return ioutils
