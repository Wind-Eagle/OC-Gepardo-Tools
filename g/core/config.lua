local ioutils = require('g.core.ioutils')

local res, err = ioutils.readAndDecode('/etc/ge.conf')
if err ~= nil then return {} end
return res
