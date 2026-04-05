local misc = {}

function misc.pickPort(modem, from)
  checkArg(1, modem, 'table')
  checkArg(2, from, 'number')
  for i = 0, 255 do
    local port = (from + i + 65534) % 65535 + 1
    if modem.open(port) then
      return port
    end
  end
  return nil
end

return misc
