local NetworkRouter = {}

function NetworkRouter:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    obj.nearestPointAddress = nil
    obj.nearestPointPort = 80

    return obj
end

function NetworkRouter:setNearestPoint(address, port)
    self.nearestPointAddress = address
    self.nearestPointPort = port
end

function NetworkRouter:getNearestPoint()
    return self.nearestPointAddress, self.nearestPointPort
end

function NetworkRouter:isReady()
    return self.nearestPointAddress ~= nil
end

return NetworkRouter
