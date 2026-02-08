local Future = {}

local thread = require("thread")
local os = require("os")

function Future:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    obj.result = nil

    return obj
end

function Future:set(value)
    self.result = value
end

function Future:get()
    while self.result == nil do
        os.sleep(0.05)
    end
    return self.result
end

return Future
