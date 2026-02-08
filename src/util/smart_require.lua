local smart_require = {}

function smart_require.reload(module_name)
    if package.loaded[module_name] ~= nil then
        package.loaded[module_name] = nil
    end
    return require(module_name)
end

return smart_require
