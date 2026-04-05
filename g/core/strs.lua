local strs = {}

function strs.contains(s, subs)
  return s:find(subs, 1, true) ~= nil
end

function strs.startsWith(s, pre)
  return s:sub(1, #pre) == pre
end

function strs.endsWith(s, suf)
  return suf == "" or s:sub(-#suf) == suf
end

return strs
