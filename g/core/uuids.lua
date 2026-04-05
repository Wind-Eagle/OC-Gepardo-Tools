local uuids = {}

function uuids.isUuid(s)
  checkArg(1, s, 'string')
  local pattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
  return s:match(pattern) ~= nil
end

return uuids
