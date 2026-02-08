local serialization = require("serialization")

local DNSStorage = {}

function DNSStorage:new(dataPath)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    obj.dataPath = dataPath
    obj.data = {}
    obj.rev_data = {}
    obj:_load(dataPath)
    return obj
end

function DNSStorage:_load(dataPath)
    local file = io.open(dataPath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        if content and content ~= "" then
            local success, loaded = pcall(serialization.unserialize, content)
            if success and loaded then
                self.data = loaded["data"]
                self.rev_data = loaded["rev_data"]
            else
                error("Data cannot be loaded")
            end
        end
    end
end

function DNSStorage:_save()
    local serialized = serialization.serialize({data = self.data, rev_data = self.rev_data})
    local file = io.open(self.dataPath, "w")
    if file then
        file:write(serialized)
        file:close()
        return true
    else
        return false
    end
end

function DNSStorage:set(address, name)
    self.data[address] = name
    self.rev_data[name] = address
    local success = self:_save()
    return success
end

function DNSStorage:getByName(name)
    local value = self.rev_data[name]
    return value
end

function DNSStorage:getByAddress(address)
    local value = self.data[address]
    return value
end

function DNSStorage:delete(address)
    if self.data[address] ~= nil then
        self.rev_data[self.data[address]] = nil
        self.data[address] = nil
        local success = self:_save()
        return success
    else
        return false
    end
end

function DNSStorage:keys()
    local keys = {}
    for key in pairs(self.data) do
        table.insert(keys, key)
    end
    return keys
end

return DNSStorage
